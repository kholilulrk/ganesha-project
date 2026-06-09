package controllers

import (
	"net/http"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

type PermissionInput struct {
	Role     string `json:"role" binding:"required"`
	Resource string `json:"resource" binding:"required"`
	Action   string `json:"action" binding:"required"`
}

func GetPermissions(c *gin.Context) {
	userRole, _ := c.Get("role")
	roleStr, _ := userRole.(string)

	var permissions []models.Permission
	if roleStr == "Super Admin" {
		if err := models.DB.Order("role, resource, action").Find(&permissions).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else {
		if err := models.DB.Where("role = ?", roleStr).Find(&permissions).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"permissions": permissions})
}

func GetPermissionsByRole(c *gin.Context) {
	role := c.Param("role")

	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	var permissions []models.Permission
	if err := models.DB.Where("role = ?", role).Find(&permissions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"permissions": permissions})
}

func GetRoles(c *gin.Context) {
	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	type RoleCount struct {
		Role  string `json:"role"`
		Count int64  `json:"count"`
	}

	var userRoles []RoleCount
	models.DB.Model(&models.User{}).
		Select("role, count(*) as count").
		Where("role != ?", "Super Admin").
		Group("role").
		Scan(&userRoles)

	roleMap := map[string]int64{}
	for _, r := range userRoles {
		roleMap[r.Role] = r.Count
	}

	allRoles := []string{"Administrasi", "Teknisi", "Logistic"}
	var roles []RoleCount
	for _, name := range allRoles {
		roles = append(roles, RoleCount{Role: name, Count: roleMap[name]})
	}

	c.JSON(http.StatusOK, gin.H{"roles": roles})
}

func UpdatePermissions(c *gin.Context) {
	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	var input struct {
		Role        string   `json:"role" binding:"required"`
		Permissions []string `json:"permissions" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := models.DB.Where("role = ?", input.Role).Delete(&models.Permission{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	for _, perm := range input.Permissions {
		resource, action := parsePerm(perm)
		if resource == "" || action == "" {
			continue
		}
		if err := models.DB.Create(&models.Permission{
			Role:     input.Role,
			Resource: resource,
			Action:   action,
		}).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Permissions updated"})
}

func ResetDefaultPermissions(c *gin.Context) {
	userRole, _ := c.Get("role")
	if userRole != "Super Admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Hanya Super Admin"})
		return
	}

	models.DB.Where("role IN ?", []string{"Administrasi", "Teknisi", "Logistic"}).Delete(&models.Permission{})
	if err := models.SeedPermissions(models.DB); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Default permissions restored"})
}

func parsePerm(p string) (string, string) {
	for _, r := range []string{"pekerjaan", "checklist", "users"} {
		for _, a := range []string{"view", "create", "edit", "delete", "manage"} {
			if p == r+"."+a {
				return r, a
			}
		}
	}
	return "", ""
}
