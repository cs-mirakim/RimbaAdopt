package com.rimba.adopt.model;

import java.io.Serializable;

public class Admin implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer adminId;
    private String position;

    public Admin() {
    }

    public Integer getAdminId() {
        return adminId;
    }

    public void setAdminId(Integer adminId) {
        this.adminId = adminId;
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }
}
