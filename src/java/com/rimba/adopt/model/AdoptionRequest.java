package com.rimba.adopt.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class AdoptionRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer requestId;
    private Integer adopterId;
    private Integer petId;
    private Integer shelterId;  // NEW FIELD
    private Timestamp requestDate;
    private String status;
    private String adopterMessage;
    private String shelterResponse;
    private String cancellationReason;

    public AdoptionRequest() {
    }

    // Getters and Setters
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

    public Integer getShelterId() {
        return shelterId;
    }

    public void setShelterId(Integer shelterId) {
        this.shelterId = shelterId;
    }

    public Timestamp getRequestDate() {
        return requestDate;
    }

    public void setRequestDate(Timestamp requestDate) {
        this.requestDate = requestDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAdopterMessage() {
        return adopterMessage;
    }

    public void setAdopterMessage(String adopterMessage) {
        this.adopterMessage = adopterMessage;
    }

    public String getShelterResponse() {
        return shelterResponse;
    }

    public void setShelterResponse(String shelterResponse) {
        this.shelterResponse = shelterResponse;
    }

    public String getCancellationReason() {
        return cancellationReason;
    }

    public void setCancellationReason(String cancellationReason) {
        this.cancellationReason = cancellationReason;
    }

}
