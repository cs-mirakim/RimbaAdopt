// 3. ADOPTER MODEL  
package com.rimba.adopt.model;

import java.io.Serializable;

public class Adopter implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer adopterId;
    private String address;
    private String occupation;
    private String householdType;
    private Integer hasOtherPets;  // Derby pakai SMALLINT/INTEGER, bukan boolean
    private String notes;

    public Adopter() {
    }

    public Integer getAdopterId() {
        return adopterId;
    }

    public void setAdopterId(Integer adopterId) {
        this.adopterId = adopterId;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getOccupation() {
        return occupation;
    }

    public void setOccupation(String occupation) {
        this.occupation = occupation;
    }

    public String getHouseholdType() {
        return householdType;
    }

    public void setHouseholdType(String householdType) {
        this.householdType = householdType;
    }

    public Integer getHasOtherPets() {
        return hasOtherPets;
    }

    public void setHasOtherPets(Integer hasOtherPets) {
        this.hasOtherPets = hasOtherPets;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
