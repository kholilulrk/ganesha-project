package controllers

import (
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"website-backend/models"
	"website-backend/services"

	"github.com/gin-gonic/gin"
	"golang.org/x/image/draw"
	_ "golang.org/x/image/webp"
)

func GetChecklist(c *gin.Context) {
	jobID := c.Param("id")
	role := c.Query("role")
	if role == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Role query parameter required"})
		return
	}
	var items []models.TaskChecklist
	if err := models.DB.Where("job_id = ? AND role = ?", jobID, role).Order("created_at ASC").Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func AddChecklistItem(c *gin.Context) {
	jobID := c.Param("id")
	userID, _ := c.Get("user_id")

	var input struct {
		Role     string  `json:"role" binding:"required"`
		Item     string  `json:"item" binding:"required"`
		Quantity int     `json:"quantity"`
		Unit     string  `json:"unit"`
		Notes    string  `json:"notes"`
		Price    float64 `json:"price"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userIDUint := userID.(uint)

	item := models.TaskChecklist{
		JobID:     parseUint(jobID),
		Role:      input.Role,
		Item:      input.Item,
		Completed: false,
		CreatedBy: userIDUint,
		Quantity:  input.Quantity,
		Unit:      input.Unit,
		Notes:     input.Notes,
		Price:     input.Price,
	}
	if err := models.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"item": item})

	var job models.Job
	if err := models.DB.First(&job, item.JobID).Error; err == nil {
		roleNames := map[string]string{"Teknisi": "Teknisi", "Logistic": "Logistic"}
		roleLabel := roleNames[input.Role]
		if roleLabel != "" {
			var targetUsers []models.User
			models.DB.Where("role = ?", input.Role).Find(&targetUsers)
			for _, u := range targetUsers {
				go services.SendPushToUser(u.ID,
					"Tugas "+roleLabel+" Baru",
					input.Item+" di pekerjaan \""+job.Name+"\"",
					"new_task", job.ID, "job",
				)
			}
		}
	}
}

func ToggleChecklistItem(c *gin.Context) {
	itemID := c.Param("itemId")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	item.Completed = !item.Completed
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func SetItemProgres(c *gin.Context) {
	itemID := c.Param("itemId")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	item.Status = "progres"
	item.Completed = false
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func SetItemSelesai(c *gin.Context) {
	itemID := c.Param("itemId")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	item.Status = "selesai"
	item.Completed = true
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func SetSharedItemProgres(c *gin.Context) {
	token := c.Param("token")
	itemID := c.Param("itemId")

	var job models.Job
	if err := models.DB.Where("share_token = ?", token).First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Link tidak valid"})
		return
	}

	var item models.TaskChecklist
	if err := models.DB.Where("id = ? AND job_id = ?", itemID, job.ID).First(&item).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	item.Status = "progres"
	item.Completed = false
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func SetSharedItemSelesai(c *gin.Context) {
	token := c.Param("token")
	itemID := c.Param("itemId")

	var job models.Job
	if err := models.DB.Where("share_token = ?", token).First(&job).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Link tidak valid"})
		return
	}

	var item models.TaskChecklist
	if err := models.DB.Where("id = ? AND job_id = ?", itemID, job.ID).First(&item).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	item.Status = "selesai"
	item.Completed = true
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func DeleteChecklistItem(c *gin.Context) {
	itemID := c.Param("itemId")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	if err := models.DB.Delete(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Item deleted"})
}

func UpdateChecklistItem(c *gin.Context) {
	itemID := c.Param("itemId")

	var input struct {
		Item     string  `json:"item"`
		Quantity int     `json:"quantity"`
		Unit     string  `json:"unit"`
		Notes    string  `json:"notes"`
		Price    float64 `json:"price"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}
	if input.Item != "" {
		item.Item = input.Item
	}
	item.Quantity = input.Quantity
	item.Unit = input.Unit
	item.Notes = input.Notes
	item.Price = input.Price
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func compressImage(path string) {
	imgFile, err := os.Open(path)
	if err != nil {
		return
	}
	defer imgFile.Close()

	img, format, err := image.Decode(imgFile)
	if err != nil {
		return
	}
	imgFile.Close()

	bounds := img.Bounds()
	w := bounds.Dx()
	h := bounds.Dy()
	const maxDim = 1920
	if w > maxDim || h > maxDim {
		if w > h {
			ratio := float64(maxDim) / float64(w)
			w = maxDim
			h = int(float64(h) * ratio)
		} else {
			ratio := float64(maxDim) / float64(h)
			h = maxDim
			w = int(float64(w) * ratio)
		}
		dst := image.NewRGBA(image.Rect(0, 0, w, h))
		draw.BiLinear.Scale(dst, dst.Bounds(), img, bounds, draw.Over, nil)
		img = dst
	}

	out, err := os.Create(path)
	if err != nil {
		return
	}
	defer out.Close()

	if format == "png" {
		enc := &png.Encoder{CompressionLevel: png.BestCompression}
		enc.Encode(out, img)
	} else {
		jpeg.Encode(out, img, &jpeg.Options{Quality: 75})
	}
}

func UploadChecklistImage(c *gin.Context) {
	itemID := c.Param("itemId")
	role := c.Query("role")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	existing := strings.Split(item.Images, ",")
	if existing[0] == "" && len(existing) == 1 && existing[0] == "" {
		existing = []string{}
	}

	maxImages := 2
	if role == "logistic" {
		maxImages = 1
	}

	if len(existing) >= maxImages {
		limit := "2"
		if role == "logistic" {
			limit = "1"
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Maksimal %s gambar", limit)})
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file provided"})
		return
	}

	ext := filepath.Ext(file.Filename)
	allowed := []string{".jpg", ".jpeg", ".png", ".gif", ".webp"}
	validExt := false
	for _, e := range allowed {
		if strings.EqualFold(ext, e) {
			validExt = true
			break
		}
	}
	if !validExt {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Hanya file gambar (jpg, png, gif, webp)"})
		return
	}

	uploadDir := "uploads/checklist"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	filename := fmt.Sprintf("%d_%s", time.Now().UnixMilli(), file.Filename)
	dst := filepath.Join(uploadDir, filename)

	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open file"})
		return
	}
	defer src.Close()

	out, err := os.Create(dst)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}
	defer out.Close()

	if _, err := io.Copy(out, src); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write file"})
		return
	}
	out.Close()

	compressImage(dst)

	existing = append(existing, filename)
	item.Images = strings.Join(existing, ",")
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"item": item})
}

func DeleteChecklistImage(c *gin.Context) {
	itemID := c.Param("itemId")
	filename := c.Query("filename")

	var item models.TaskChecklist
	if err := models.DB.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	images := strings.Split(item.Images, ",")
	var updated []string
	for _, img := range images {
		if img != filename {
			updated = append(updated, img)
		}
	}
	item.Images = strings.Join(updated, ",")
	if err := models.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	os.Remove(filepath.Join("uploads/checklist", filename))
	c.JSON(http.StatusOK, gin.H{"item": item})
}

func parseUint(s string) uint {
	id, err := strconv.ParseUint(s, 10, 64)
	if err != nil {
		return 0
	}
	return uint(id)
}
