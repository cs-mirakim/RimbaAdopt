package com.rimba.adopt.controller;

import com.rimba.adopt.dao.LostReportDAO;
import com.rimba.adopt.model.LostReport;
import com.rimba.adopt.util.SessionUtil;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ManageLostAnimalServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 1, // 1 MB
    maxFileSize = 1024 * 1024 * 5,       // 5 MB
    maxRequestSize = 1024 * 1024 * 10    // 10 MB
)
public class ManageLostAnimalServlet extends HttpServlet {
    private LostReportDAO lostReportDAO;
    
    @Override
    public void init() throws ServletException {
        lostReportDAO = new LostReportDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (!SessionUtil.isLoggedIn(session)) {
            sendErrorResponse(response, "Unauthorized access. Please login first.");
            return;
        }

        String action = request.getParameter("action");
        
        try {
            if ("getAll".equals(action)) {
                getAllLostReports(request, response);
            } else if ("getById".equals(action)) {
                getLostReportById(request, response);
            } else if ("getByAdopter".equals(action)) {
                getLostReportsByAdopter(request, response, session);
            } else if ("search".equals(action)) {
                searchLostReports(request, response);
            } else if ("getStats".equals(action)) {
                getStatistics(response);
            } else {
                sendErrorResponse(response, "Invalid action parameter");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendErrorResponse(response, "Database error: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (!SessionUtil.isLoggedIn(session)) {
            sendErrorResponse(response, "Unauthorized access. Please login first.");
            return;
        }

        String action = request.getParameter("action");
        
        try {
            if ("create".equals(action)) {
                createLostReport(request, response, session);
            } else if ("update".equals(action)) {
                updateLostReport(request, response);
            } else if ("updateStatus".equals(action)) {
                updateLostReportStatus(request, response);
            } else if ("delete".equals(action)) {
                deleteLostReport(request, response);
            } else {
                sendErrorResponse(response, "Invalid action parameter");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendErrorResponse(response, "Database error: " + e.getMessage());
        } catch (ParseException e) {
            e.printStackTrace();
            sendErrorResponse(response, "Invalid date format");
        }
    }

    // GET Methods
    private void getAllLostReports(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            // Get pagination parameters
            int page = 1;
            int limit = 8;
            
            try {
                page = Integer.parseInt(request.getParameter("page"));
            } catch (NumberFormatException e) {
                page = 1;
            }
            
            try {
                limit = Integer.parseInt(request.getParameter("limit"));
            } catch (NumberFormatException e) {
                limit = 8;
            }
            
            List<Map<String, Object>> reports = lostReportDAO.getAllLostReportsWithAdopter();
            
            // Apply pagination
            int total = reports.size();
            int start = Math.min((page - 1) * limit, total);
            int end = Math.min(start + limit, total);
            
            List<Map<String, Object>> paginatedReports = reports.subList(start, end);
            
            // Build JSON manually
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"success\": true,");
            json.append("\"total\": ").append(total).append(",");
            json.append("\"page\": ").append(page).append(",");
            json.append("\"limit\": ").append(limit).append(",");
            json.append("\"totalPages\": ").append((int) Math.ceil((double) total / limit)).append(",");
            json.append("\"reports\": [");
            
            for (int i = 0; i < paginatedReports.size(); i++) {
                Map<String, Object> report = paginatedReports.get(i);
                if (i > 0) json.append(",");
                
                String reportJson = convertMapToJson(report);
                json.append(reportJson);
            }
            
            json.append("]}");
            
            out.print(json.toString());
            
        } catch (Exception e) {
            String errorJson = "{\"success\": false, \"message\": \"Error retrieving lost reports: " + 
                              e.getMessage().replace("\"", "\\\"") + "\"}";
            out.print(errorJson);
        }
        
        out.flush();
    }

    private void getLostReportById(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int lostId = Integer.parseInt(request.getParameter("lostId"));
            Map<String, Object> report = lostReportDAO.getLostReportWithAdopterById(lostId);
            
            if (report != null) {
                String reportJson = convertMapToJson(report);
                String json = "{\"success\": true, \"report\": " + reportJson + "}";
                out.print(json);
            } else {
                out.print("{\"success\": false, \"message\": \"Lost report not found\"}");
            }
            
        } catch (NumberFormatException e) {
            out.print("{\"success\": false, \"message\": \"Invalid lost ID format\"}");
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error retrieving lost report: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void getLostReportsByAdopter(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int adopterId = SessionUtil.getUserId(session);
            List<LostReport> reports = lostReportDAO.getLostReportsByAdopter(adopterId);
            
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"success\": true,");
            json.append("\"count\": ").append(reports.size()).append(",");
            json.append("\"reports\": [");
            
            for (int i = 0; i < reports.size(); i++) {
                LostReport report = reports.get(i);
                if (i > 0) json.append(",");
                
                // Create a simple map for each report
                StringBuilder reportJson = new StringBuilder();
                reportJson.append("{");
                reportJson.append("\"lost_id\": ").append(report.getLostId()).append(",");
                reportJson.append("\"pet_name\": \"").append(escapeJson(report.getPetName())).append("\",");
                reportJson.append("\"species\": \"").append(escapeJson(report.getSpecies())).append("\",");
                reportJson.append("\"status\": \"").append(escapeJson(report.getStatus())).append("\",");
                reportJson.append("\"last_seen_location\": \"").append(escapeJson(report.getLastSeenLocation())).append("\",");
                reportJson.append("\"last_seen_date\": \"").append(report.getLastSeenDate() != null ? report.getLastSeenDate().toString() : "").append("\",");
                reportJson.append("\"photo_path\": \"").append(escapeJson(report.getPhotoPath() != null ? report.getPhotoPath() : "animal_picture/default_lost_pet.jpg")).append("\"");
                reportJson.append("}");
                
                json.append(reportJson);
            }
            
            json.append("]}");
            
            out.print(json.toString());
            
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error retrieving your lost reports: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void searchLostReports(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String status = request.getParameter("status");
            String species = request.getParameter("species");
            String location = request.getParameter("location");
            String dateFilter = request.getParameter("dateFilter");
            
            Integer daysAgo = null;
            if (dateFilter != null && !dateFilter.isEmpty()) {
                try {
                    daysAgo = Integer.parseInt(dateFilter);
                } catch (NumberFormatException e) {
                    // Ignore invalid numbers
                }
            }
            
            List<Map<String, Object>> reports = lostReportDAO.searchLostReportsWithAdopter(status, species, location, daysAgo);
            
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"success\": true,");
            json.append("\"count\": ").append(reports.size()).append(",");
            json.append("\"reports\": [");
            
            for (int i = 0; i < reports.size(); i++) {
                Map<String, Object> report = reports.get(i);
                if (i > 0) json.append(",");
                
                String reportJson = convertMapToJson(report);
                json.append(reportJson);
            }
            
            json.append("]}");
            
            out.print(json.toString());
            
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error searching lost reports: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void getStatistics(HttpServletResponse response) throws SQLException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int totalLost = lostReportDAO.countLostReportsByStatus("lost");
            int totalFound = lostReportDAO.countLostReportsByStatus("found");
            
            String json = String.format(
                "{\"success\": true, \"totalLost\": %d, \"totalFound\": %d, \"total\": %d}",
                totalLost, totalFound, totalLost + totalFound
            );
            
            out.print(json);
            
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error retrieving statistics: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    // POST Methods
    private void createLostReport(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws SQLException, IOException, ParseException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int adopterId = SessionUtil.getUserId(session);
            String petName = request.getParameter("pet_name");
            String species = request.getParameter("species");
            String lastSeenLocation = request.getParameter("last_seen_location");
            String lastSeenDateStr = request.getParameter("last_seen_date");
            String description = request.getParameter("description");
            String contactInfo = request.getParameter("contact_info");
            
            // Validate required fields
            if (petName == null || petName.trim().isEmpty() ||
                species == null || species.trim().isEmpty() ||
                lastSeenLocation == null || lastSeenLocation.trim().isEmpty()) {
                
                out.print("{\"success\": false, \"message\": \"Required fields are missing\"}");
                out.flush();
                return;
            }
            
            LostReport lostReport = new LostReport();
            lostReport.setAdopterId(adopterId);
            lostReport.setPetName(petName.trim());
            lostReport.setSpecies(species.trim());
            lostReport.setLastSeenLocation(lastSeenLocation.trim());
            
            // Parse date
            if (lastSeenDateStr != null && !lastSeenDateStr.isEmpty()) {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                java.util.Date utilDate = sdf.parse(lastSeenDateStr);
                lostReport.setLastSeenDate(new Date(utilDate.getTime()));
            } else {
                lostReport.setLastSeenDate(new Date(System.currentTimeMillis()));
            }
            
            // Combine description with contact info
            String fullDescription = (description != null ? description.trim() : "") + 
                                   "\n\nContact Information: " + 
                                   (contactInfo != null ? contactInfo.trim() : "");
            lostReport.setDescription(fullDescription);
            
            // Set default photo path
            lostReport.setPhotoPath("animal_picture/default_lost_pet.jpg");
            lostReport.setStatus("lost"); // Default status
            
            int lostId = lostReportDAO.createLostReport(lostReport);
            
            if (lostId > 0) {
                out.print("{\"success\": true, \"message\": \"Lost report created successfully\", \"lostId\": " + lostId + "}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to create lost report\"}");
            }
            
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error creating lost report: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void updateLostReport(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException, ParseException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int lostId = Integer.parseInt(request.getParameter("lostId"));
            String petName = request.getParameter("pet_name");
            String species = request.getParameter("species");
            String lastSeenLocation = request.getParameter("last_seen_location");
            String lastSeenDateStr = request.getParameter("last_seen_date");
            String description = request.getParameter("description");
            String status = request.getParameter("status");
            
            // Get existing report (need to create a new one)
            LostReport lostReport = new LostReport();
            lostReport.setLostId(lostId);
            
            // Update fields
            if (petName != null) lostReport.setPetName(petName.trim());
            if (species != null) lostReport.setSpecies(species.trim());
            if (lastSeenLocation != null) lostReport.setLastSeenLocation(lastSeenLocation.trim());
            if (description != null) lostReport.setDescription(description.trim());
            if (status != null) lostReport.setStatus(status.trim());
            
            // Parse date
            if (lastSeenDateStr != null && !lastSeenDateStr.isEmpty()) {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                java.util.Date utilDate = sdf.parse(lastSeenDateStr);
                lostReport.setLastSeenDate(new Date(utilDate.getTime()));
            }
            
            boolean success = lostReportDAO.updateLostReport(lostReport);
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"Lost report updated successfully\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to update lost report\"}");
            }
            
        } catch (NumberFormatException e) {
            out.print("{\"success\": false, \"message\": \"Invalid lost ID format\"}");
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error updating lost report: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void updateLostReportStatus(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int lostId = Integer.parseInt(request.getParameter("lostId"));
            String status = request.getParameter("status");
            
            if (status == null || (!status.equals("lost") && !status.equals("found"))) {
                out.print("{\"success\": false, \"message\": \"Invalid status value. Must be 'lost' or 'found'\"}");
                out.flush();
                return;
            }
            
            boolean success = lostReportDAO.updateLostReportStatus(lostId, status);
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"Status updated successfully to: " + status + "\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to update status\"}");
            }
            
        } catch (NumberFormatException e) {
            out.print("{\"success\": false, \"message\": \"Invalid lost ID format\"}");
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error updating status: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    private void deleteLostReport(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int lostId = Integer.parseInt(request.getParameter("lostId"));
            
            boolean success = lostReportDAO.deleteLostReport(lostId);
            
            if (success) {
                out.print("{\"success\": true, \"message\": \"Lost report deleted successfully\"}");
            } else {
                out.print("{\"success\": false, \"message\": \"Failed to delete lost report\"}");
            }
            
        } catch (NumberFormatException e) {
            out.print("{\"success\": false, \"message\": \"Invalid lost ID format\"}");
        } catch (Exception e) {
            out.print("{\"success\": false, \"message\": \"Error deleting lost report: " + 
                     e.getMessage().replace("\"", "\\\"") + "\"}");
        }
        
        out.flush();
    }

    // Helper Methods
    private String convertMapToJson(Map<String, Object> report) {
        StringBuilder json = new StringBuilder();
        json.append("{");
        
        boolean first = true;
        for (Map.Entry<String, Object> entry : report.entrySet()) {
            if (!first) json.append(",");
            first = false;
            
            String key = entry.getKey();
            Object value = entry.getValue();
            
            json.append("\"").append(key).append("\": ");
            
            if (value == null) {
                json.append("null");
            } else if (value instanceof Number) {
                json.append(value);
            } else if (value instanceof Boolean) {
                json.append(value);
            } else {
                // Escape special characters in string
                json.append("\"").append(escapeJson(value.toString())).append("\"");
            }
        }
        
        json.append("}");
        return json.toString();
    }
    
    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }

    private void sendErrorResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        String errorJson = "{\"success\": false, \"message\": \"" + escapeJson(message) + "\"}";
        out.print(errorJson);
        out.flush();
    }
}