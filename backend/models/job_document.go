package models

type JobDocument struct {
	ID       uint   `gorm:"primaryKey" json:"id"`
	JobID    uint   `json:"job_id"`
	DocType  string `json:"doc_type"`
	FileName string `json:"file_name"`
	FilePath string `json:"file_path"`
}

type JobVerification struct {
	ID      uint   `gorm:"primaryKey" json:"id"`
	JobID   uint   `json:"job_id"`
	Step    string `json:"step"`
	Checked bool   `json:"checked"`
}
