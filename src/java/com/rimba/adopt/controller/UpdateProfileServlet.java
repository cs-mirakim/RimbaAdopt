package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UserDao;
import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Admin;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.model.Shelter;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "UpdateProfileServlet", urlPatterns = {"/update-profile"})
public class UpdateProfileServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Check if user is logged in
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("role");

        UserDao userDao = new UserDao();
        boolean success = false;

        try {
            // Update Users table (common data)
            Users user = new Users();
            user.setUserId(userId);
            user.setName(request.getParameter("name"));
            user.setEmail(request.getParameter("email"));
            user.setPhone(request.getParameter("phone"));
            user.setProfilePhotoPath(request.getParameter("profile_photo_path"));

            success = userDao.updateUserProfile(user);

            if (success) {
                // Update session data
                session.setAttribute("name", user.getName());
                session.setAttribute("email", user.getEmail());
                session.setAttribute("phone", user.getPhone());

                // Update role-specific data
                if ("admin".equals(role)) {
                    Admin admin = new Admin();
                    admin.setAdminId(userId);
                    admin.setPosition(request.getParameter("position"));
                    success = userDao.updateAdminProfile(admin);

                    if (success) {
                        session.setAttribute("position", admin.getPosition());
                    }

                } else if ("adopter".equals(role)) {
                    Adopter adopter = new Adopter();
                    adopter.setAdopterId(userId);
                    adopter.setAddress(request.getParameter("address"));
                    adopter.setOccupation(request.getParameter("occupation"));
                    adopter.setHouseholdType(request.getParameter("household_type"));

                    // Handle has_other_pets (convert string to integer)
                    String hasOtherPets = request.getParameter("has_other_pets");
                    if (hasOtherPets != null) {
                        adopter.setHasOtherPets("true".equalsIgnoreCase(hasOtherPets) ? 1 : 0);
                    }

                    adopter.setNotes(request.getParameter("notes"));
                    success = userDao.updateAdopterProfile(adopter);

                    if (success) {
                        session.setAttribute("address", adopter.getAddress());
                        session.setAttribute("occupation", adopter.getOccupation());
                        session.setAttribute("householdType", adopter.getHouseholdType());
                    }

                } else if ("shelter".equals(role)) {
                    Shelter shelter = new Shelter();
                    shelter.setShelterId(userId);
                    shelter.setShelterName(request.getParameter("shelter_name"));
                    shelter.setShelterAddress(request.getParameter("shelter_address"));
                    shelter.setShelterDescription(request.getParameter("shelter_description"));
                    shelter.setWebsite(request.getParameter("website"));
                    shelter.setOperatingHours(request.getParameter("operating_hours"));
                    success = userDao.updateShelterProfile(shelter);

                    if (success) {
                        session.setAttribute("shelterName", shelter.getShelterName());
                        session.setAttribute("shelterAddress", shelter.getShelterAddress());
                    }
                }
            }

            if (success) {
                session.setAttribute("successMessage", "Profile updated successfully!");
            } else {
                session.setAttribute("errorMessage", "Failed to update profile. Please try again.");
            }

            response.sendRedirect("profile");

        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("errorMessage", "Database error occurred. Please try again.");
            response.sendRedirect("profile");
        }
    }
}
