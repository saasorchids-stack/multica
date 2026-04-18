package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	db "github.com/multica-ai/multica/server/pkg/db/generated"
)

// newResourceID creates a new UUIDv7 string for a resource.
func newResourceID() string {
	id, _ := uuid.NewV7()
	var pg pgtype.UUID
	pg.Valid = true
	copy(pg.Bytes[:], id[:])
	return uuidToString(pg)
}

// ---------------------------------------------------------------------------
// Session Resources CRUD
// ---------------------------------------------------------------------------

// Resource represents a single item attached to a session (file, repo, etc.)
type ResourceResponse struct {
	ID          string          `json:"id"`
	Type        string          `json:"type"`
	Name        string          `json:"name"`
	URI         string          `json:"uri,omitempty"`
	ContentType string          `json:"content_type,omitempty"`
	SizeBytes   int64           `json:"size_bytes,omitempty"`
	Metadata    json.RawMessage `json:"metadata,omitempty"`
}

// ListSessionResources returns all resources attached to a session.
func (h *Handler) ListSessionResources(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireUserID(w, r); !ok {
		return
	}
	workspaceID := ctxWorkspaceID(r.Context())
	sessionID := chi.URLParam(r, "sessionId")

	session, err := h.Queries.GetManagedSessionInWorkspace(r.Context(), db.GetManagedSessionInWorkspaceParams{
		ID:          parseUUID(sessionID),
		WorkspaceID: parseUUID(workspaceID),
	})
	if err != nil {
		writeError(w, http.StatusNotFound, "session not found")
		return
	}

	var resources []ResourceResponse
	if session.Resources != nil && len(session.Resources) > 2 {
		json.Unmarshal(session.Resources, &resources)
	}
	if resources == nil {
		resources = []ResourceResponse{}
	}

	writeJSON(w, http.StatusOK, map[string]any{"data": resources})
}

// AddSessionResource adds a resource to a session.
func (h *Handler) AddSessionResource(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireUserID(w, r); !ok {
		return
	}
	workspaceID := ctxWorkspaceID(r.Context())
	sessionID := chi.URLParam(r, "sessionId")

	if _, err := h.Queries.GetManagedSessionInWorkspace(r.Context(), db.GetManagedSessionInWorkspaceParams{
		ID:          parseUUID(sessionID),
		WorkspaceID: parseUUID(workspaceID),
	}); err != nil {
		writeError(w, http.StatusNotFound, "session not found")
		return
	}

	var req ResourceResponse
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Type == "" {
		writeError(w, http.StatusBadRequest, "type is required")
		return
	}
	if req.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}
	if req.ID == "" {
		req.ID = newResourceID()
	}

	// Wrap in array for JSONB append
	resourceJSON, _ := json.Marshal([]ResourceResponse{req})

	session, err := h.Queries.AddManagedSessionResource(r.Context(), parseUUID(sessionID), resourceJSON)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to add resource")
		return
	}

	var resources []ResourceResponse
	json.Unmarshal(session.Resources, &resources)
	writeJSON(w, http.StatusCreated, map[string]any{"data": resources})
}

// GetSessionResource returns a single resource from a session by ID.
func (h *Handler) GetSessionResource(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireUserID(w, r); !ok {
		return
	}
	workspaceID := ctxWorkspaceID(r.Context())
	sessionID := chi.URLParam(r, "sessionId")
	resourceID := chi.URLParam(r, "resourceId")

	session, err := h.Queries.GetManagedSessionInWorkspace(r.Context(), db.GetManagedSessionInWorkspaceParams{
		ID:          parseUUID(sessionID),
		WorkspaceID: parseUUID(workspaceID),
	})
	if err != nil {
		writeError(w, http.StatusNotFound, "session not found")
		return
	}

	var resources []ResourceResponse
	json.Unmarshal(session.Resources, &resources)

	for _, res := range resources {
		if res.ID == resourceID {
			writeJSON(w, http.StatusOK, res)
			return
		}
	}

	writeError(w, http.StatusNotFound, "resource not found")
}

// UpdateSessionResource updates a resource in a session by ID.
func (h *Handler) UpdateSessionResource(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireUserID(w, r); !ok {
		return
	}
	workspaceID := ctxWorkspaceID(r.Context())
	sessionID := chi.URLParam(r, "sessionId")
	resourceID := chi.URLParam(r, "resourceId")

	session, err := h.Queries.GetManagedSessionInWorkspace(r.Context(), db.GetManagedSessionInWorkspaceParams{
		ID:          parseUUID(sessionID),
		WorkspaceID: parseUUID(workspaceID),
	})
	if err != nil {
		writeError(w, http.StatusNotFound, "session not found")
		return
	}

	var update ResourceResponse
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	var resources []ResourceResponse
	json.Unmarshal(session.Resources, &resources)

	found := false
	for i, res := range resources {
		if res.ID == resourceID {
			if update.Type != "" {
				resources[i].Type = update.Type
			}
			if update.Name != "" {
				resources[i].Name = update.Name
			}
			if update.URI != "" {
				resources[i].URI = update.URI
			}
			if update.ContentType != "" {
				resources[i].ContentType = update.ContentType
			}
			if update.SizeBytes > 0 {
				resources[i].SizeBytes = update.SizeBytes
			}
			if update.Metadata != nil {
				resources[i].Metadata = update.Metadata
			}
			found = true
			break
		}
	}
	if !found {
		writeError(w, http.StatusNotFound, "resource not found")
		return
	}

	newResources, _ := json.Marshal(resources)
	h.Queries.SetManagedSessionResources(r.Context(), parseUUID(sessionID), newResources)

	writeJSON(w, http.StatusOK, map[string]any{"data": resources})
}

// DeleteSessionResource removes a resource from a session by ID.
func (h *Handler) DeleteSessionResource(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireUserID(w, r); !ok {
		return
	}
	workspaceID := ctxWorkspaceID(r.Context())
	sessionID := chi.URLParam(r, "sessionId")
	resourceID := chi.URLParam(r, "resourceId")

	session, err := h.Queries.GetManagedSessionInWorkspace(r.Context(), db.GetManagedSessionInWorkspaceParams{
		ID:          parseUUID(sessionID),
		WorkspaceID: parseUUID(workspaceID),
	})
	if err != nil {
		writeError(w, http.StatusNotFound, "session not found")
		return
	}

	var resources []ResourceResponse
	json.Unmarshal(session.Resources, &resources)

	filtered := make([]ResourceResponse, 0, len(resources))
	found := false
	for _, res := range resources {
		if res.ID == resourceID {
			found = true
			continue
		}
		filtered = append(filtered, res)
	}
	if !found {
		writeError(w, http.StatusNotFound, "resource not found")
		return
	}

	newResources, _ := json.Marshal(filtered)
	h.Queries.SetManagedSessionResources(r.Context(), parseUUID(sessionID), newResources)

	w.WriteHeader(http.StatusNoContent)
}
