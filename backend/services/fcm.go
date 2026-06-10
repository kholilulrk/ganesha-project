package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"website-backend/config"
	"website-backend/models"

	"github.com/golang-jwt/jwt/v5"
)

type ServiceAccount struct {
	Type                    string `json:"type"`
	ProjectID               string `json:"project_id"`
	PrivateKeyID            string `json:"private_key_id"`
	PrivateKey              string `json:"private_key"`
	ClientEmail             string `json:"client_email"`
	ClientID                string `json:"client_id"`
	AuthURI                 string `json:"auth_uri"`
	TokenURI                string `json:"token_uri"`
	AuthProviderX509CertURL string `json:"auth_provider_x509_cert_url"`
	ClientX509CertURL       string `json:"client_x509_cert_url"`
}

type FCMV1Message struct {
	Message struct {
		Token        string            `json:"token"`
		Notification *FCMNotification  `json:"notification,omitempty"`
		Data         map[string]string `json:"data,omitempty"`
		Android      *FCMAndroidConfig `json:"android,omitempty"`
	} `json:"message"`
}

type FCMNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type FCMAndroidConfig struct {
	Priority    string             `json:"priority"`
	Notification *FCMAndroidNotification `json:"notification,omitempty"`
}

type FCMAndroidNotification struct {
	ClickAction string `json:"click_action"`
	Sound       string `json:"sound"`
}

type OAuth2Response struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   int    `json:"expires_in"`
}

var (
	accessToken     string
	accessTokenExp  time.Time
)

func getAccessToken() (string, error) {
	if accessToken != "" && time.Now().Before(accessTokenExp) {
		return accessToken, nil
	}

	path := config.AppConfig.FCMServiceAccountPath
	if path == "" {
		return "", fmt.Errorf("FCM_SERVICE_ACCOUNT_PATH not set")
	}

	sa, err := loadServiceAccount(path)
	if err != nil {
		return "", err
	}

	now := time.Now()
	claims := jwt.MapClaims{
		"iss":   sa.ClientEmail,
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
		"aud":   sa.TokenURI,
		"exp":   now.Add(3600 * time.Second).Unix(),
		"iat":   now.Unix(),
	}

	key, err := jwt.ParseRSAPrivateKeyFromPEM([]byte(sa.PrivateKey))
	if err != nil {
		return "", fmt.Errorf("parse private key: %w", err)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	assertion, err := token.SignedString(key)
	if err != nil {
		return "", fmt.Errorf("sign jwt: %w", err)
	}

	body := fmt.Sprintf("grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=%s", assertion)
	resp, err := http.Post(sa.TokenURI, "application/x-www-form-urlencoded", bytes.NewBufferString(body))
	if err != nil {
		return "", fmt.Errorf("oauth2 request: %w", err)
	}
	defer resp.Body.Close()

	var oauth OAuth2Response
	if err := json.NewDecoder(resp.Body).Decode(&oauth); err != nil {
		return "", fmt.Errorf("decode oauth2 response: %w", err)
	}

	accessToken = oauth.AccessToken
	accessTokenExp = now.Add(time.Duration(oauth.ExpiresIn-60) * time.Second)
	return accessToken, nil
}

func loadServiceAccount(path string) (*ServiceAccount, error) {
	saJSON, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read service account file: %w", err)
	}
	var sa ServiceAccount
	if err := json.Unmarshal(saJSON, &sa); err != nil {
		return nil, fmt.Errorf("parse service account: %w", err)
	}
	return &sa, nil
}

func SendPushToUser(userID uint, title, body, notifType string, refID uint, refType string) {
	var tokens []models.FCMToken
	models.DB.Where("user_id = ?", userID).Find(&tokens)
	if len(tokens) == 0 {
		return
	}

	notification := models.Notification{
		UserID:  userID,
		Title:   title,
		Body:    body,
		Type:    notifType,
		RefID:   refID,
		RefType: refType,
	}
	models.DB.Create(&notification)

	token, err := getAccessToken()
	if err != nil {
		return
	}

	sa, _ := loadServiceAccount(config.AppConfig.FCMServiceAccountPath)
	if sa == nil {
		return
	}

	for _, t := range tokens {
		sendFCMV1(t.Token, title, body, notifType, fmt.Sprintf("%d", refID), refType, token, sa.ProjectID)
	}
}

func SendPushToRoles(roles []string, title, body, notifType string, refID uint, refType string) {
	var users []models.User
	models.DB.Where("role IN ?", roles).Find(&users)
	for _, u := range users {
		SendPushToUser(u.ID, title, body, notifType, refID, refType)
	}
}

func SendPushToAllUsers(title, body, notifType string, refID uint, refType string) {
	var users []models.User
	models.DB.Find(&users)
	for _, u := range users {
		SendPushToUser(u.ID, title, body, notifType, refID, refType)
	}
}

func sendFCMV1(token, title, body, notifType, refID, refType, bearer, projectID string) {
	msg := FCMV1Message{}
	msg.Message.Token = token
	msg.Message.Notification = &FCMNotification{Title: title, Body: body}
	msg.Message.Data = map[string]string{
		"type":    notifType,
		"ref_id":  refID,
		"ref_type": refType,
	}
	msg.Message.Android = &FCMAndroidConfig{
		Priority: "high",
		Notification: &FCMAndroidNotification{
			ClickAction: "FLUTTER_NOTIFICATION_CLICK",
			Sound:       "default",
		},
	}

	payload, _ := json.Marshal(msg)
	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", projectID)

	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(payload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+bearer)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == 401 {
		accessToken = ""
	}
}


