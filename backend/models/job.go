package models

import (
	"crypto/rand"
	"encoding/hex"
	"time"
	"gorm.io/gorm"
)

type Job struct {
	gorm.Model
	Name         string    `json:"name" gorm:"not null"`
	Description  string    `json:"description"`
	Value        float64   `json:"value"`
	ContractDate time.Time `json:"contract_date"`
	Share        string    `json:"share"`
	Status       string    `json:"status" gorm:"default:pending"`
	Dateline     time.Time `json:"dateline"`
	AssignedTo   string    `json:"assigned_to"`
	Spektek      string    `json:"spektek"`
	Progress     string    `json:"progress"`
	TDM                       string `json:"tdm"`
	TDS                       string `json:"tds"`
	ShareToken                string `json:"share_token" gorm:"uniqueIndex"`
	UncompletedLogisticCount int64  `json:"uncompleted_logistic" gorm:"-"`
	UncompletedTeknisiCount  int64  `json:"uncompleted_teknisi" gorm:"-"`
}

func (j *Job) GenerateShareToken() string {
	b := make([]byte, 16)
	rand.Read(b)
	token := hex.EncodeToString(b)
	j.ShareToken = token
	return token
}
