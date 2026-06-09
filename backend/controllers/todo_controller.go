package controllers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func getCurrentUserID(c *gin.Context) uint {
	raw, exists := c.Get("user_id")
	if !exists {
		return 0
	}
	switch v := raw.(type) {
	case float64:
		return uint(v)
	case uint:
		return v
	case int:
		return uint(v)
	case int64:
		return uint(v)
	case string:
		id, _ := strconv.ParseUint(v, 10, 64)
		return uint(id)
	case json.Number:
		id, _ := v.Int64()
		return uint(id)
	default:
		fmt.Printf("todo: unexpected type for user_id: %T\n", raw)
		return 0
	}
}

func GetTodos(c *gin.Context) {
	currentUserID := getCurrentUserID(c)

	var todos []models.Todo
	if err := models.DB.Where("assigned_to = ? OR created_by = ?", currentUserID, currentUserID).Order("created_at DESC").Find(&todos).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"todos": todos})
}

func CreateTodo(c *gin.Context) {
	currentUserID := getCurrentUserID(c)

	var input struct {
		Task       string `json:"task" binding:"required"`
		AssignedTo uint   `json:"assigned_to"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	assignedTo := input.AssignedTo
	if assignedTo == 0 {
		assignedTo = currentUserID
	}

	todo := models.Todo{
		Task:       input.Task,
		Status:     "pending",
		AssignedTo: assignedTo,
		CreatedBy:  currentUserID,
	}

	if err := models.DB.Create(&todo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"todo": todo})
}

func ToggleTodo(c *gin.Context) {
	id := c.Param("id")
	var todo models.Todo
	if err := models.DB.First(&todo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Todo not found"})
		return
	}

	if todo.Status == "done" {
		todo.Status = "pending"
	} else {
		todo.Status = "done"
	}

	if err := models.DB.Save(&todo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"todo": todo})
}

func DeleteTodo(c *gin.Context) {
	id := c.Param("id")
	var todo models.Todo
	if err := models.DB.First(&todo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Todo not found"})
		return
	}

	if err := models.DB.Delete(&todo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Todo deleted"})
}
