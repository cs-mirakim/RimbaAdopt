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

@WebServlet(name = "ProfileServlet", urlPatterns = {"/profile"})
public class ProfileServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
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

        try {
            // Get user basic info
            Users user = userDao.getUserById(userId);
            if (user == null) {
                session.invalidate();
                response.sendRedirect("login.jsp");
                return;
            }

            // Store user data in request attributes
            request.setAttribute("user", user);

            // Get role-specific data
            if ("admin".equals(role)) {
                Admin admin = userDao.getAdminDetails(userId);
                request.setAttribute("admin", admin);

            } else if ("adopter".equals(role)) {
                Adopter adopter = userDao.getAdopterDetails(userId);
                request.setAttribute("adopter", adopter);

            } else if ("shelter".equals(role)) {
                Shelter shelter = userDao.getShelterDetails(userId);
                request.setAttribute("shelter", shelter);
            }

            // Forward to profile page
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("profile.jsp").forward(request, response);
        }
    }
}
