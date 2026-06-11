package routes

import (
	"website-backend/controllers"
	"website-backend/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter(r *gin.Engine) {
	r.Static("/uploads", "./uploads")
	api := r.Group("/api")
	{
		api.GET("/s/:token", controllers.SharedJobPreview)
		auth := api.Group("/auth")
		{
			auth.POST("/register", controllers.Register)
			auth.POST("/login", controllers.Login)
		}

		shared := api.Group("/jobs/shared")
		{
			shared.GET("/:token", controllers.ShowSharedJob)
			shared.POST("/:token/comments", controllers.StoreSharedComment)
			shared.PUT("/:token/checklist/:itemId/progres", controllers.SetSharedItemProgres)
			shared.PUT("/:token/checklist/:itemId/selesai", controllers.SetSharedItemSelesai)
		}

		public := api.Group("/fcm")
		{
			public.GET("/test/:userId", controllers.TestFCMPush)
		}

		protected := api.Group("/")
		protected.Use(middleware.AuthRequired())
		protected.Use(middleware.ActivityLogger())
		{
			protected.GET("/dashboard", controllers.GetDashboardStats)
			protected.GET("/permissions", controllers.GetPermissions)
			protected.GET("/permissions/roles", controllers.GetRoles)
			protected.GET("/permissions/:role", controllers.GetPermissionsByRole)
			protected.PUT("/permissions", controllers.UpdatePermissions)
			protected.POST("/permissions/reset", controllers.ResetDefaultPermissions)
			protected.GET("/profile", controllers.GetProfile)
			protected.PUT("/profile", controllers.UpdateProfile)
			protected.GET("/users", controllers.GetUsers)
			protected.POST("/users", controllers.CreateUser)
			protected.PUT("/users/:id", controllers.UpdateUser)
			protected.DELETE("/users/:id", controllers.DeleteUser)
			protected.POST("/upload", controllers.UploadFile)
			protected.GET("/jobs", controllers.GetJobs)
			protected.GET("/jobs/:id", controllers.GetJob)
			protected.POST("/jobs", controllers.CreateJob)
			protected.PUT("/jobs/:id", controllers.UpdateJob)
			protected.DELETE("/jobs/:id", controllers.DeleteJob)
			protected.POST("/jobs/:id/share-link", controllers.GenerateShareLink)
			protected.PUT("/jobs/:id/complete", controllers.CompleteJob)
			protected.GET("/surats", controllers.GetSurats)
		protected.GET("/surats/expiring", controllers.GetExpiringSurats)
		protected.GET("/surats/:id", controllers.GetSurat)
		protected.POST("/surats", controllers.CreateSurat)
		protected.PUT("/surats/:id", controllers.UpdateSurat)
		protected.DELETE("/surats/:id", controllers.DeleteSurat)
		protected.GET("/documents", controllers.GetDocuments)
		protected.GET("/documents/:id", controllers.GetDocument)
		protected.POST("/documents", controllers.CreateDocument)
		protected.PUT("/documents/:id", controllers.UpdateDocument)
		protected.DELETE("/documents/:id", controllers.DeleteDocument)
		protected.GET("/todos", controllers.GetTodos)
		protected.POST("/todos", controllers.CreateTodo)
		protected.PUT("/todos/:id/toggle", controllers.ToggleTodo)
		protected.DELETE("/todos/:id", controllers.DeleteTodo)
		protected.GET("/calendar-events", controllers.GetCalendarEvents)
		protected.POST("/calendar-events", controllers.CreateCalendarEvent)
		protected.PUT("/calendar-events/:id", controllers.UpdateCalendarEvent)
		protected.DELETE("/calendar-events/:id", controllers.DeleteCalendarEvent)
		protected.GET("/sph", controllers.GetSphs)
		protected.GET("/sph/:id", controllers.GetSph)
		protected.POST("/sph", controllers.CreateSph)
		protected.PUT("/sph/:id", controllers.UpdateSph)
		protected.DELETE("/sph/:id", controllers.DeleteSph)
			protected.GET("/vendors", controllers.GetVendors)
			protected.GET("/vendors/:id", controllers.GetVendor)
			protected.POST("/vendors", controllers.CreateVendor)
			protected.PUT("/vendors/:id", controllers.UpdateVendor)
			protected.DELETE("/vendors/:id", controllers.DeleteVendor)
			protected.GET("/vendors/:id/payment-terms", controllers.GetVendorPaymentTerms)
			protected.POST("/vendors/:id/payment-terms", controllers.CreatePaymentTerm)
			protected.PUT("/vendors/:id/payment-terms/:termId", controllers.UpdatePaymentTerm)
			protected.DELETE("/vendors/:id/payment-terms/:termId", controllers.DeletePaymentTerm)
			protected.GET("/activity-logs", controllers.GetActivityLogs)
			protected.GET("/activity-logs/settings", controllers.GetActivityLogSettings)
			protected.PUT("/activity-logs/settings", controllers.UpdateActivityLogSettings)
			protected.POST("/fcm/register", controllers.RegisterFCMToken)
			protected.POST("/fcm/unregister", controllers.UnregisterFCMToken)
			protected.GET("/notifications", controllers.GetNotifications)
			protected.GET("/notifications/unread-count", controllers.GetUnreadNotificationCount)
			protected.PUT("/notifications/:id/read", controllers.MarkNotificationRead)
			protected.PUT("/notifications/read-all", controllers.MarkAllNotificationsRead)
			protected.GET("/jobs/:id/checklist", controllers.GetChecklist)
			protected.POST("/jobs/:id/checklist", controllers.AddChecklistItem)
			protected.PUT("/jobs/:id/checklist/:itemId", controllers.ToggleChecklistItem)
			protected.PATCH("/jobs/:id/checklist/:itemId", controllers.UpdateChecklistItem)
			protected.PUT("/jobs/:id/checklist/:itemId/progres", controllers.SetItemProgres)
			protected.PUT("/jobs/:id/checklist/:itemId/selesai", controllers.SetItemSelesai)
			protected.POST("/jobs/:id/checklist/:itemId/images", controllers.UploadChecklistImage)
			protected.DELETE("/jobs/:id/checklist/:itemId/images", controllers.DeleteChecklistImage)
			protected.DELETE("/jobs/:id/checklist/:itemId", controllers.DeleteChecklistItem)
		}

		jobDocs := api.Group("/jobs/:id")
		jobDocs.Use(middleware.AuthRequired())
		{
			jobDocs.GET("/documents", controllers.GetJobDocuments)
			jobDocs.POST("/documents", controllers.UploadJobDocument)
			jobDocs.DELETE("/documents/:docId", controllers.DeleteJobDocument)
			jobDocs.PATCH("/status", controllers.UpdateJobStatus)
			jobDocs.PATCH("/doc-dates", controllers.UpdateJobDocDates)
			jobDocs.PUT("/verification", controllers.UpdateJobVerification)
			jobDocs.PUT("/progress", controllers.UpdateJobProgress)
			jobDocs.GET("/comments", controllers.GetComments)
			jobDocs.POST("/comments", controllers.AddComment)
			jobDocs.DELETE("/comments/:commentId", controllers.DeleteComment)
		}
	}

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})
	r.GET("/sitemap.xml", controllers.GetSitemap)
}
