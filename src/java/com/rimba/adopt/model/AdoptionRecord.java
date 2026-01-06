package com.rimba.adopt.model;

import java.io.Serializable;
import java.sql.Date;

public class AdoptionRecord implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer recordId;
    private Integer requestId;           // ID adoption request sahaja
    private Integer adopterId;           // ID adopter sahaja
    private Integer petId;               // ID pet sahaja
    private Date adoptionDate;
    private String remarks;

    public AdoptionRecord() {
    }

    // Getters and Setters
    public Integer getRecordId() {
        return recordId;
    }

    public void setRecordId(Integer recordId) {
        this.recordId = recordId;
    }

    public Integer getRequestId() {
        return requestId;
    }

    public void setRequestId(Integer requestId) {
        this.requestId = requestId;
    }

    public Integer getAdopterId() {
        return adopterId;
    }

    public void setAdopterId(Integer adopterId) {
        this.adopterId = adopterId;
    }

    public Integer getPetId() {
        return petId;
    }

    public void setPetId(Integer petId) {
        this.petId = petId;
    }

    public Date getAdoptionDate() {
        return adoptionDate;
    }

    public void setAdoptionDate(Date adoptionDate) {
        this.adoptionDate = adoptionDate;
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
    }
}
