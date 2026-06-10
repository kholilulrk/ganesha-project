package controllers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
	"website-backend/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := models.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": user})
}

func UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := models.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	name := c.PostForm("name")
	username := c.PostForm("username")
	phone := c.PostForm("phone")
	password := c.PostForm("password")

	if name != "" {
		user.Name = name
	}
	if username != "" {
		var existing models.User
		if err := models.DB.Where("username = ? AND id != ?", username, userID).First(&existing).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
			return
		}
		user.Username = username
	}
	if phone != "" {
		user.Phone = phone
	}
	if password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
			return
		}
		user.Password = string(hashedPassword)
	}

	file, err := c.FormFile("photo")
	if err == nil {
		uploadDir := "uploads/profiles"
		os.MkdirAll(uploadDir, os.ModePerm)
		ext := filepath.Ext(file.Filename)
		filename := fmt.Sprintf("%d_%d%s", userID, time.Now().UnixMilli(), ext)
		savePath := filepath.Join(uploadDir, filename)
		if err := c.SaveUploadedFile(file, savePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save photo"})
			return
		}

		// Delete old photo if exists
		if user.Photo != "" {
			oldPath := "." + user.Photo
			if _, err := os.Stat(oldPath); err == nil {
				os.Remove(oldPath)
			}
		}

		user.Photo = "/" + savePath
	}

	if err := models.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": user})
}

func CreateUser(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if roleStr != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin yang dapat menambah pengguna"})
		return
	}

	var input struct {
		Name     string `json:"name" binding:"required"`
		Username string `json:"username" binding:"required"`
		Role     string `json:"role" binding:"required"`
		Password string `json:"password" binding:"required,min=6"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	user := models.User{
		Name:     input.Name,
		Username: input.Username,
		Role:     input.Role,
		Password: string(hashedPassword),
	}

	if err := models.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"user": user})
}

func GetUsers(c *gin.Context) {
	rolesParam := c.Query("roles")
	var users []models.User
	query := models.DB.Order("name ASC")
	if rolesParam != "" {
		roles := strings.Split(rolesParam, ",")
		for i := range roles {
			roles[i] = strings.TrimSpace(roles[i])
		}
		query = query.Where("role IN ?", roles)
	}
	if err := query.Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}

func UpdateUser(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if roleStr != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin yang dapat mengedit pengguna"})
		return
	}

	id := c.Param("id")
	var user models.User
	if err := models.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var input struct {
		Name     string `json:"name"`
		Username string `json:"username"`
		Role     string `json:"role"`
		Phone    string `json:"phone"`
		Password string `json:"password"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.Name != "" {
		user.Name = input.Name
	}
	if input.Username != "" {
		user.Username = input.Username
	}
	if input.Role != "" {
		user.Role = input.Role
	}
	if input.Phone != "" {
		user.Phone = input.Phone
	}
	if input.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
			return
		}
		user.Password = string(hashedPassword)
	}

	if err := models.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": user})
}

func DeleteUser(c *gin.Context) {
	role, _ := c.Get("role")
	roleStr, _ := role.(string)
	if roleStr != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin yang dapat menghapus pengguna"})
		return
	}

	id := c.Param("id")
	var user models.User
	if err := models.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if err := models.DB.Unscoped().Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}
