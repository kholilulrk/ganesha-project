package models

import "gorm.io/gorm"

type Permission struct {
	ID       uint   `gorm:"primaryKey" json:"id"`
	Role     string `gorm:"uniqueIndex:idx_role_res_act;not null" json:"role"`
	Resource string `gorm:"uniqueIndex:idx_role_res_act;not null" json:"resource"`
	Action   string `gorm:"uniqueIndex:idx_role_res_act;not null" json:"action"`
}

var DefaultPermissions = []Permission{
	{Role: "Administrasi", Resource: "pekerjaan", Action: "view"},
	{Role: "Administrasi", Resource: "pekerjaan", Action: "create"},
	{Role: "Administrasi", Resource: "pekerjaan", Action: "edit"},
	{Role: "Administrasi", Resource: "pekerjaan", Action: "delete"},
	{Role: "Administrasi", Resource: "users", Action: "view"},
	{Role: "Administrasi", Resource: "users", Action: "create"},
	{Role: "Administrasi", Resource: "users", Action: "edit"},
	{Role: "Administrasi", Resource: "users", Action: "delete"},
	{Role: "Administrasi", Resource: "pengumuman", Action: "view"},
	{Role: "Administrasi", Resource: "pengumuman", Action: "create"},
	{Role: "Administrasi", Resource: "pengumuman", Action: "edit"},
	{Role: "Administrasi", Resource: "pengumuman", Action: "delete"},
	{Role: "Administrasi", Resource: "vendor", Action: "view"},
	{Role: "Administrasi", Resource: "vendor", Action: "create"},
	{Role: "Administrasi", Resource: "vendor", Action: "edit"},
	{Role: "Administrasi", Resource: "vendor", Action: "delete"},
	{Role: "Administrasi", Resource: "absensi", Action: "view"},
	{Role: "Teknisi", Resource: "pekerjaan", Action: "view"},
	{Role: "Teknisi", Resource: "pekerjaan", Action: "edit"},
	{Role: "Teknisi", Resource: "checklist", Action: "manage"},
	{Role: "Logistic", Resource: "pekerjaan", Action: "view"},
	{Role: "Logistic", Resource: "checklist", Action: "manage"},
	{Role: "Administrasi", Resource: "company", Action: "manage"},
}

func SeedPermissions(db *gorm.DB) error {
	for _, p := range DefaultPermissions {
		var existing Permission
		err := db.Where("role = ? AND resource = ? AND action = ?", p.Role, p.Resource, p.Action).
			First(&existing).Error
		if err == gorm.ErrRecordNotFound {
			if err := db.Create(&p).Error; err != nil {
				return err
			}
		} else if err != nil {
			return err
		}
	}
	return nil
}
