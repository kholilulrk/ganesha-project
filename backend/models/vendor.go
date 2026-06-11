package models

import (
	"gorm.io/gorm"
)

type Vendor struct {
	gorm.Model
	Name          string        `json:"name" gorm:"not null"`
	ContactPerson string        `json:"contact_person"`
	Phone         string        `json:"phone"`
	Email         string        `json:"email"`
	Address       string        `json:"address"`
	Description   string        `json:"description"`
	JobID         *uint         `json:"job_id"`
	Job           *Job          `json:"job" gorm:"foreignKey:JobID"`
	PaymentTerms  []PaymentTerm `json:"payment_terms" gorm:"foreignKey:VendorID"`
}

type PaymentTerm struct {
	gorm.Model
	VendorID    uint      `json:"vendor_id" gorm:"not null;index"`
	TermNumber  int       `json:"term_number" gorm:"not null"`
	Percentage  float64   `json:"percentage"`
	Amount      float64   `json:"amount"`
	DueDate     string    `json:"due_date"`
	Description string    `json:"description"`
}

func (v *Vendor) AfterFind(tx *gorm.DB) error {
	if v.Job != nil && v.Job.ID == 0 {
		v.Job = nil
	}
	return nil
}
