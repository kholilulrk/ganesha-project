package models

import (
	"time"
	"gorm.io/gorm"
)

type Surat struct {
	gorm.Model
	NamaSurat   string    `json:"nama_surat" gorm:"not null"`
	StartAktif  time.Time `json:"start_aktif" gorm:"not null"`
	JenisSurat  string    `json:"jenis_surat" gorm:"not null"`
	MasaBerlaku time.Time `json:"masa_berlaku" gorm:"not null"`
}
