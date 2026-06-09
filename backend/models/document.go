package models

import "gorm.io/gorm"

type Document struct {
	gorm.Model
	NamaDokumen string `json:"nama_dokumen" gorm:"not null"`
	TipeDokumen string `json:"tipe_dokumen" gorm:"not null"`
	FilePath    string `json:"file_path" gorm:"not null"`
	Deskripsi   string `json:"deskripsi"`
	ShareMode   string `json:"share_mode" gorm:"default:all"`
	SharedTo    string `json:"shared_to"`
	UploadedBy  uint   `json:"uploaded_by"`
}
