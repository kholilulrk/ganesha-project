package controllers

import (
	"fmt"
	"net/http"
	"website-backend/config"
	"website-backend/models"

	"github.com/gin-gonic/gin"
)

func GetSitemap(c *gin.Context) {
	baseURL := config.AppConfig.AppURL

	var jobs []models.Job
	models.DB.Where("share_token IS NOT NULL AND share_token != ''").Find(&jobs)

	xml := `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>` + baseURL + `/</loc>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>`

	for _, job := range jobs {
		xml += fmt.Sprintf(`
  <url>
    <loc>%s/pekerjaan/shared/%s</loc>
    <changefreq>daily</changefreq>
    <priority>0.8</priority>
  </url>`, baseURL, job.ShareToken)
	}

	xml += `
</urlset>`

	c.Header("Content-Type", "application/xml")
	c.String(http.StatusOK, xml)
}
