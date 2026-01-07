package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UserDao;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;

@WebServlet(name = "DeleteProfileServlet", urlPatterns = {"/delete-profile"})
public class DeleteProfileServlet extends HttpServlet {

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
        UserDao userDao = new UserDao();

        // Confirm password (optional - for security)
        String password = request.getParameter("password");
        if (password != null && !password.isEmpty()) {
            // Validate password before deletion
            // You might want to implement password validation here
        }

        // Delete user
        boolean deleted = userDao.deleteUser(userId);

        if (deleted) {
            // Invalidate session
            if (session != null) {
                session.invalidate();
            }
            response.sendRedirect("login.jsp?message=Account deleted successfully");
        } else {
            session.setAttribute("errorMessage", "Failed to delete account. Please try again.");
            response.sendRedirect("profile");
        }
    }
}
