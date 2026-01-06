package com.rimba.adopt.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class AwarenessBanner implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer bannerId;
    private String title;
    private String description;
    private String imagePath;
    private String status;
    private Timestamp createdAt;
    private Integer createdBy;           // ID admin sahaja

    public AwarenessBanner() {
    }

    // Getters and Setters
    public Integer getBannerId() {
        return bannerId;
    }

    public void setBannerId(Integer bannerId) {
        this.bannerId = bannerId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(Integer createdBy) {
        this.createdBy = createdBy;
    }
}
