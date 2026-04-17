package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"
)

const (
	// envKey is the environment variable holding the hex-encoded 32-byte key.
	envKey = "ENCRYPTION_KEY"
	// prefix distinguishes encrypted values from plaintext for migration.
	prefix = "enc::"
)

var (
	cachedKey []byte
	keyOnce   sync.Once
)

// encryptionKey lazily loads the key from the environment.
func encryptionKey() ([]byte, error) {
	var loadErr error
	keyOnce.Do(func() {
		raw := strings.TrimSpace(os.Getenv(envKey))
		if raw == "" {
			loadErr = fmt.Errorf("crypto: %s not set", envKey)
			return
		}
		decoded, err := base64.StdEncoding.DecodeString(raw)
		if err != nil {
			loadErr = fmt.Errorf("crypto: %s must be base64-encoded: %w", envKey, err)
			return
		}
		if len(decoded) != 32 {
			loadErr = fmt.Errorf("crypto: %s must decode to 32 bytes (got %d)", envKey, len(decoded))
			return
		}
		cachedKey = decoded
	})
	if loadErr != nil {
		return nil, loadErr
	}
	if cachedKey == nil {
		return nil, fmt.Errorf("crypto: %s not set", envKey)
	}
	return cachedKey, nil
}

// Encrypt encrypts plaintext using AES-256-GCM and returns a base64 string
// prefixed with "enc::".
func Encrypt(plaintext string) (string, error) {
	key, err := encryptionKey()
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("crypto: new cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("crypto: new gcm: %w", err)
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("crypto: read nonce: %w", err)
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return prefix + base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts a value produced by Encrypt. If the value is not prefixed
// with "enc::", it is returned as-is (backward compatibility with unencrypted data).
func Decrypt(encoded string) (string, error) {
	if !strings.HasPrefix(encoded, prefix) {
		// Plaintext (not yet encrypted) — return as-is for migration.
		return encoded, nil
	}

	key, err := encryptionKey()
	if err != nil {
		return "", err
	}

	data, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(encoded, prefix))
	if err != nil {
		return "", fmt.Errorf("crypto: base64 decode: %w", err)
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("crypto: new cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("crypto: new gcm: %w", err)
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", fmt.Errorf("crypto: ciphertext too short")
	}

	nonce, ciphertext := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", fmt.Errorf("crypto: decrypt: %w", err)
	}

	return string(plaintext), nil
}

// IsAvailable returns true if the encryption key is configured.
func IsAvailable() bool {
	_, err := encryptionKey()
	return err == nil
}

// EncryptMap encrypts all values in a map (for custom_env).
func EncryptMap(m map[string]string) (map[string]string, error) {
	if !IsAvailable() {
		return m, nil // No key configured — pass through.
	}
	result := make(map[string]string, len(m))
	for k, v := range m {
		enc, err := Encrypt(v)
		if err != nil {
			return nil, fmt.Errorf("encrypt key %q: %w", k, err)
		}
		result[k] = enc
	}
	return result, nil
}

// DecryptMap decrypts all values in a map (for custom_env).
// Values not prefixed with "enc::" are returned as-is.
func DecryptMap(m map[string]string) (map[string]string, error) {
	result := make(map[string]string, len(m))
	for k, v := range m {
		dec, err := Decrypt(v)
		if err != nil {
			return nil, fmt.Errorf("decrypt key %q: %w", k, err)
		}
		result[k] = dec
	}
	return result, nil
}
