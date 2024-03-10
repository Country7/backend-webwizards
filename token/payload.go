package token

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/google/uuid"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrExpiredToken = errors.New("expired token")
)

type Payload struct {
	ID        uuid.UUID `json:"id"`
	Username  string    `json:"username"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiredAt time.Time `json:"expired_at"`
	NotBefore time.Time `json:"not_before"`
}

func (p Payload) GetExpirationTime() (*jwt.NumericDate, error) {
	return jwt.NewNumericDate(p.ExpiredAt), nil
}

func (p Payload) GetIssuedAt() (*jwt.NumericDate, error) {
	return jwt.NewNumericDate(p.IssuedAt), nil
}

func (p Payload) GetNotBefore() (*jwt.NumericDate, error) {
	return jwt.NewNumericDate(p.NotBefore), nil
}

func (p Payload) GetIssuer() (string, error) {
	return "issuer", nil
}

func (p Payload) GetSubject() (string, error) {
	return "subject", nil
}

func (p Payload) GetAudience() (jwt.ClaimStrings, error) {
	return jwt.ClaimStrings{"audience"}, nil
}

func (p Payload) Valid() error {
	if p.ExpiredAt.Before(time.Now()) {
		return ErrExpiredToken
	}

	return nil
}

// NewPayload creates a new token payload with a specific username and duration.
func NewPayload(username string, duration time.Duration) (*Payload, error) {
	tokenID, err := uuid.NewRandom()
	if err != nil {
		return nil, err
	}

	payload := &Payload{
		ID:        tokenID,
		Username:  username,
		IssuedAt:  time.Now(),
		ExpiredAt: time.Now().Add(duration),
	}

	return payload, nil
}
