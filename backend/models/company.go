package models

import (
	"gorm.io/gorm"
)

type CompanyProfile struct {
	gorm.Model
	CompanyName    string `json:"company_name" gorm:"not null"`
	Tagline        string `json:"tagline"`
	Logo           string `json:"logo"`
	HeroImage      string `json:"hero_image"`
	AboutTitle     string `json:"about_title"`
	AboutDesc      string `json:"about_desc" gorm:"type:text"`
	AboutImage     string `json:"about_image"`
	Services       []CompanyService `json:"services" gorm:"foreignKey:CompanyProfileID"`
	Partners       []CompanyPartner `json:"partners" gorm:"foreignKey:CompanyProfileID"`
}

type CompanyService struct {
	gorm.Model
	CompanyProfileID uint   `json:"company_profile_id" gorm:"not null;index"`
	Title            string `json:"title" gorm:"not null"`
	Description      string `json:"description" gorm:"type:text"`
	Icon             string `json:"icon"`
	SortOrder        int    `json:"sort_order" gorm:"default:0"`
}

type CompanyPartner struct {
	gorm.Model
	CompanyProfileID uint   `json:"company_profile_id" gorm:"not null;index"`
	Name             string `json:"name" gorm:"not null"`
	Logo             string `json:"logo"`
	Description      string `json:"description" gorm:"type:text"`
	Website          string `json:"website"`
	SortOrder        int    `json:"sort_order" gorm:"default:0"`
}
