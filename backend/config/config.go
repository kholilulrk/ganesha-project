package config

import (
	"os"
	"github.com/joho/godotenv"
)

type Config struct {
	DBHost                 string
	DBPort                 string
	DBUser                 string
	DBPassword             string
	DBName                 string
	JWTSecret              string
	ServerPort             string
	AppURL                 string
	FCMServiceAccountPath string
	AppLatestVersion      string
	AppDownloadURL        string
}

var AppConfig *Config

func LoadConfig() {
	godotenv.Load()

	AppConfig = &Config{
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "root"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "website"),
		JWTSecret:  getEnv("JWT_SECRET", "secret-key-change-in-production"),
		ServerPort: getEnv("SERVER_PORT", "8080"),
		AppURL:                getEnv("APP_URL", "http://localhost:5173"),
		FCMServiceAccountPath: getEnv("FCM_SERVICE_ACCOUNT_PATH", ""),
		AppLatestVersion:      getEnv("APP_LATEST_VERSION", "1.0.0"),
		AppDownloadURL:        getEnv("APP_DOWNLOAD_URL", ""),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
