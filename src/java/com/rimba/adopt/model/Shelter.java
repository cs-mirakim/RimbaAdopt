package com.rimba.adopt.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class Shelter implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer shelterId;
    private String shelterName;
    private String shelterAddress;
    private String shelterDescription;
    private String website;
    private String operatingHours;
    private String approvalStatus;
    private Integer reviewedBy;
    private Timestamp reviewedAt;
    private String approvalMessage;
    private String rejectionReason;
    private Integer notificationSent;
    private Timestamp notificationSentAt;

    public Shelter() {
    }

    public Integer getShelterId() {
        return shelterId;
    }

    public void setShelterId(Integer shelterId) {
        this.shelterId = shelterId;
    }

    public String getShelterName() {
        return shelterName;
    }

    public void setShelterName(String shelterName) {
        this.shelterName = shelterName;
    }

    public String getShelterAddress() {
        return shelterAddress;
    }

    public void setShelterAddress(String shelterAddress) {
        this.shelterAddress = shelterAddress;
    }

    public String getShelterDescription() {
        return shelterDescription;
    }

    public void setShelterDescription(String shelterDescription) {
        this.shelterDescription = shelterDescription;
    }

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public String getOperatingHours() {
        return operatingHours;
    }

    public void setOperatingHours(String operatingHours) {
        this.operatingHours = operatingHours;
    }

    public String getApprovalStatus() {
        return approvalStatus;
    }

    public void setApprovalStatus(String approvalStatus) {
        this.approvalStatus = approvalStatus;
    }

    public Integer getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(Integer reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public Timestamp getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(Timestamp reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public String getApprovalMessage() {
        return approvalMessage;
    }

    public void setApprovalMessage(String approvalMessage) {
        this.approvalMessage = approvalMessage;
    }

    public String getRejectionReason() {
        return rejectionReason;
    }

    public void setRejectionReason(String rejectionReason) {
        this.rejectionReason = rejectionReason;
    }

    public Integer getNotificationSent() {
        return notificationSent;
    }

    public void setNotificationSent(Integer notificationSent) {
        this.notificationSent = notificationSent;
    }

    public Timestamp getNotificationSentAt() {
        return notificationSentAt;
    }

    public void setNotificationSentAt(Timestamp notificationSentAt) {
        this.notificationSentAt = notificationSentAt;
    }
}
