package middleware

import (
	"log/slog"
	"net/http"
	"strings"
	"sync"
	"time"
)

// tokenBucket implements a simple token-bucket rate limiter.
type tokenBucket struct {
	tokens     float64
	capacity   float64
	refillRate float64 // tokens per second
	lastRefill time.Time
}

func (b *tokenBucket) allow() bool {
	now := time.Now()
	elapsed := now.Sub(b.lastRefill).Seconds()
	b.tokens += elapsed * b.refillRate
	if b.tokens > b.capacity {
		b.tokens = b.capacity
	}
	b.lastRefill = now

	if b.tokens >= 1 {
		b.tokens--
		return true
	}
	return false
}

// RateLimiter is a per-key in-memory rate limiter.
type RateLimiter struct {
	mu       sync.Mutex
	buckets  map[string]*tokenBucket
	capacity float64
	rate     float64 // tokens per second
}

// NewRateLimiter creates a rate limiter. capacity is burst size, rate is
// sustained requests per second.
func NewRateLimiter(capacity float64, rate float64) *RateLimiter {
	rl := &RateLimiter{
		buckets:  make(map[string]*tokenBucket),
		capacity: capacity,
		rate:     rate,
	}
	// Evict stale buckets every 5 minutes.
	go rl.evictLoop()
	return rl
}

func (rl *RateLimiter) evictLoop() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		for key, b := range rl.buckets {
			// Remove entries idle for more than 10 minutes.
			if now.Sub(b.lastRefill) > 10*time.Minute {
				delete(rl.buckets, key)
			}
		}
		rl.mu.Unlock()
	}
}

// Allow checks whether the given key is within the rate limit.
func (rl *RateLimiter) Allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	b, ok := rl.buckets[key]
	if !ok {
		b = &tokenBucket{
			tokens:     rl.capacity,
			capacity:   rl.capacity,
			refillRate: rl.rate,
			lastRefill: time.Now(),
		}
		rl.buckets[key] = b
	}
	return b.allow()
}

// clientIP extracts the real client IP, preferring X-Forwarded-For (first hop)
// then X-Real-IP, then RemoteAddr.
func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.SplitN(xff, ",", 2)
		ip := strings.TrimSpace(parts[0])
		if ip != "" {
			return ip
		}
	}
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return strings.TrimSpace(xri)
	}
	// RemoteAddr is "host:port"
	addr := r.RemoteAddr
	if idx := strings.LastIndex(addr, ":"); idx != -1 {
		return addr[:idx]
	}
	return addr
}

// RateLimit returns a Chi middleware that applies per-IP rate limiting.
// burst is the max burst size, rps is sustained requests per second.
func RateLimit(burst float64, rps float64) func(http.Handler) http.Handler {
	rl := NewRateLimiter(burst, rps)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Use authenticated user ID if present, otherwise IP.
			key := r.Header.Get("X-User-ID")
			if key == "" {
				key = "ip:" + clientIP(r)
			}

			if !rl.Allow(key) {
				slog.Warn("rate limit exceeded", "key", key, "path", r.URL.Path)
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("Retry-After", "1")
				w.WriteHeader(http.StatusTooManyRequests)
				w.Write([]byte(`{"error":"rate limit exceeded"}`))
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// StrictRateLimit is a tighter rate limiter for sensitive endpoints (auth, etc.).
func StrictRateLimit(burst float64, rps float64) func(http.Handler) http.Handler {
	rl := NewRateLimiter(burst, rps)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			key := "ip:" + clientIP(r)

			if !rl.Allow(key) {
				slog.Warn("strict rate limit exceeded", "key", key, "path", r.URL.Path)
				w.Header().Set("Content-Type", "application/json")
				w.Header().Set("Retry-After", "5")
				w.WriteHeader(http.StatusTooManyRequests)
				w.Write([]byte(`{"error":"rate limit exceeded"}`))
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
