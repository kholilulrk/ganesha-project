package models

import (
	"fmt"
	"gorm.io/gorm"
	"gorm.io/driver/mysql"
	"website-backend/config"
	"golang.org/x/crypto/bcrypt"
)

var DB *gorm.DB

func ConnectDatabase() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.AppConfig.DBUser,
		config.AppConfig.DBPassword,
		config.AppConfig.DBHost,
		config.AppConfig.DBPort,
		config.AppConfig.DBName,
	)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}

	DB = db

	if err := db.AutoMigrate(&User{}, &Job{}, &TaskChecklist{}, &Permission{}, &JobDocument{}, &JobVerification{}, &Comment{}, &Surat{}, &Document{}, &Todo{}, &CalendarEvent{}, &Sph{}, &SphTeknisi{}, &ActivityLog{}, &AppSetting{}); err != nil {
		return err
	}

	db.Exec("DROP INDEX uni_users_email ON users")
	db.Exec("ALTER TABLE users DROP COLUMN email")

	if db.Migrator().HasColumn(&Permission{}, "deleted_at") {
		db.Migrator().DropColumn(&Permission{}, "deleted_at")
		db.Exec("DELETE FROM permissions")
		db.Exec("ALTER TABLE permissions AUTO_INCREMENT = 1")
	}

	if err := SeedPermissions(db); err != nil {
		return err
	}

	if err := FixMissingShareTokens(db); err != nil {
		return err
	}

	if err := SeedDefaultSettings(); err != nil {
		return err
	}

	return SeedSuperAdmin()
}

func FixMissingShareTokens(db *gorm.DB) error {
	var jobs []Job
	if err := db.Where("share_token = '' OR share_token IS NULL").Find(&jobs).Error; err != nil {
		return err
	}
	for i := range jobs {
		jobs[i].GenerateShareToken()
	}
	if len(jobs) > 0 {
		return db.Save(&jobs).Error
	}
	return nil
}

func SeedDefaultSettings() error {
	return DB.Where(AppSetting{Key: "activity_log_retention_days"}).FirstOrCreate(&AppSetting{Key: "activity_log_retention_days", Value: "30"}).Error
}

func SeedSuperAdmin() error {
	var count int64
	DB.Model(&User{}).Where("username = ?", "ganeshaenergi516").Count(&count)
	if count > 0 {
		return nil
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte("password"), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	superAdmin := User{
		Name:     "Super Admin",
		Username: "ganeshaenergi516",
		Role:     "Super Admin",
		Password: string(hashedPassword),
	}

	return DB.Create(&superAdmin).Error
}
