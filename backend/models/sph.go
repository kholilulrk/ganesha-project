package models

import "gorm.io/gorm"

type Sph struct {
	gorm.Model
	JobID               uint        `json:"job_id" gorm:"not null"`
	Job                 Job         `json:"job" gorm:"foreignKey:JobID"`
	NomorSph            string      `json:"nomor_sph"`
	TanggalSph          string      `json:"tanggal_sph"`
	Jenis               string      `json:"jenis" gorm:"default:dalam_kota"`
	NilaiJasa           float64     `json:"nilai_jasa"`
	NilaiMaterial       float64     `json:"nilai_material"`
	TransportPerHari    float64     `json:"transport_per_hari"`
	UangMakanPerHari    float64     `json:"uang_makan_per_hari"`
	JumlahHari          int         `json:"jumlah_hari"`
	Akomodasi           float64     `json:"akomodasi"`
	BiayaLain           float64     `json:"biaya_lain"`
	KeteranganBiayaLain string      `json:"keterangan_biaya_lain"`
	Overhead            float64     `json:"overhead"`
	MarginKeuntungan    float64     `json:"margin_keuntungan"`
	Catatan             string      `json:"catatan"`
	CreatedBy           uint        `json:"created_by"`
	Teknisi             []SphTeknisi `json:"teknisi" gorm:"foreignKey:SphID"`
}

type SphTeknisi struct {
	gorm.Model
	SphID         uint    `json:"sph_id" gorm:"not null"`
	NamaTeknisi   string  `json:"nama_teknisi"`
	UpahPerBulan  float64 `json:"upah_per_bulan"`
	JumlahBulan   int     `json:"jumlah_bulan"`
}
