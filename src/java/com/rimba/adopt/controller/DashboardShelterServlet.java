package com.rimba.adopt.controller;

import com.rimba.adopt.dao.AdoptionRequestDAO;
import com.rimba.adopt.dao.FeedbackDAO;
import com.rimba.adopt.dao.PetsDAO;
import com.rimba.adopt.util.SessionUtil;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/dashboard_shelter")
public class DashboardShelterServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        
        // Check if user is logged in and is shelter
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }
        
        try {
            int shelterId = SessionUtil.getUserId(session);
            
            // Get DAO instances
            PetsDAO petsDAO = new PetsDAO();
            AdoptionRequestDAO adoptionRequestDAO = new AdoptionRequestDAO();
            FeedbackDAO feedbackDAO = new FeedbackDAO();
            
            // Get statistics
            int totalPets = petsDAO.countPetsByShelter(shelterId);
            int pendingRequests = adoptionRequestDAO.countPendingRequests(shelterId);
            
            // Get counts for all statuses
            Map<String, Integer> requestCounts = adoptionRequestDAO.countRequestsByStatus(shelterId);
            int approvedRequests = requestCounts.getOrDefault("approved", 0);
            int rejectedRequests = requestCounts.getOrDefault("rejected", 0);
            int cancelledRequests = requestCounts.getOrDefault("cancelled", 0);
            
            // Get average rating
            double averageRating = feedbackDAO.getAverageRatingByShelterId(shelterId);
            
            // Get monthly statistics for charts
            Map<String, Object> monthlyStats = adoptionRequestDAO.getMonthlyRequestStats(shelterId);
            Map<String, Object> monthlyFeedbackStats = feedbackDAO.getMonthlyFeedbackStats(shelterId);
            
            // Debug: Print data to console
            System.out.println("=== DASHBOARD DATA FOR SHELTER ID: " + shelterId + " ===");
            System.out.println("Total Pets: " + totalPets);
            System.out.println("Pending Requests: " + pendingRequests);
            System.out.println("Approved Requests: " + approvedRequests);
            System.out.println("Rejected Requests: " + rejectedRequests);
            System.out.println("Cancelled Requests: " + cancelledRequests);
            System.out.println("Average Rating: " + averageRating);
            
            // Set attributes for JSP
            request.setAttribute("totalPets", totalPets);
            request.setAttribute("pendingRequests", pendingRequests);
            request.setAttribute("approvedRequests", approvedRequests);
            request.setAttribute("rejectedRequests", rejectedRequests);
            request.setAttribute("cancelledRequests", cancelledRequests);
            request.setAttribute("averageRating", averageRating);
            request.setAttribute("monthlyStats", monthlyStats);
            request.setAttribute("monthlyFeedbackStats", monthlyFeedbackStats);
            
            // Forward to JSP
            request.getRequestDispatcher("dashboard_shelter.jsp").forward(request, response);
            
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage());
            request.getRequestDispatcher("error.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System error: " + e.getMessage());
            request.getRequestDispatcher("error.jsp").forward(request, response);
        }
    }
}