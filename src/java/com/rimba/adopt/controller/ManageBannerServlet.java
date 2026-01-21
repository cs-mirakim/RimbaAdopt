package com.rimba.adopt.controller;

import com.rimba.adopt.dao.BannerDao;
import com.rimba.adopt.util.SessionUtil;
import java.io.*;
import java.nio.file.*;
import java.sql.Timestamp;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.*;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@MultipartConfig(
        fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB max (matching JSP)
        maxRequestSize = 1024 * 1024 * 10 // 10MB
)
@WebServlet("/ManageBannerServlet")
public class ManageBannerServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(ManageBannerServlet.class.getName());

    private BannerDao bannerDao;

    @Override
    public void init() throws ServletException {
        bannerDao = new BannerDao();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check if user is logged in and is admin
        HttpSession session = request.getSession(false);
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdmin(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            deleteBanner(request, response);
        } else {
            getAllBanners(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check if user is logged in and is admin
        HttpSession session = request.getSession(false);
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdmin(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        String action = request.getParameter("action");

        if (action == null) {
            response.sendRedirect("manage_banner.jsp");
            return;
        }

        switch (action) {
            case "add":
                addBanner(request, response);
                break;
            case "update_caption":
                updateCaption(request, response);
                break;
            case "update_order":
                updateOrder(request, response);
                break;
            case "update_status":
                updateStatus(request, response);
                break;
            case "save_order":
                saveAllOrders(request, response);
                break;
            default:
                response.sendRedirect("manage_banner.jsp");
                break;
        }
    }

    private void getAllBanners(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // === ADD DEBUG LOGGING ===
            logger.info("=== GET ALL BANNERS START ===");

            List<Map<String, Object>> banners = bannerDao.getAllBannersWithDetails();

            logger.info("Banners fetched from DAO: " + (banners != null ? banners.size() : "NULL"));

            if (banners != null && !banners.isEmpty()) {
                for (Map<String, Object> banner : banners) {
                    logger.info("Banner ID: " + banner.get("bannerId")
                            + ", Title: " + banner.get("title")
                            + ", ImagePath: " + banner.get("imagePath"));
                }
            }

            request.setAttribute("banners", banners);

            // Calculate stats
            long totalStorage = bannerDao.getTotalStorageUsed();
            int activeCount = bannerDao.getActiveBannerCount();
            int totalCount = bannerDao.getTotalBannerCount();

            logger.info("Stats - Total: " + totalCount + ", Active: " + activeCount + ", Storage: " + totalStorage);

            request.setAttribute("totalStorage", totalStorage);
            request.setAttribute("activeCount", activeCount);
            request.setAttribute("totalCount", totalCount);

            // Max banners is 10 (as per JSP)
            request.setAttribute("maxBanners", 10);

            logger.info("=== GET ALL BANNERS END ===");

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error getting banners", e);
            request.setAttribute("errorMessage", "Error loading banners: " + e.getMessage());
            request.setAttribute("banners", new ArrayList<>()); // Empty list to prevent null pointer
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("manage_banner.jsp");
        dispatcher.forward(request, response);
    }

    private void addBanner(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Get form parameters
            String title = request.getParameter("title");
            String caption = request.getParameter("caption");
            String positionStr = request.getParameter("position");
            String active = request.getParameter("active");

            // Validate parameters
            if (title == null || title.trim().isEmpty()) {
                response.sendRedirect("manage_banner.jsp?error=Banner+title+is+required");
                return;
            }

            if (caption == null || caption.trim().isEmpty()) {
                response.sendRedirect("manage_banner.jsp?error=Banner+caption+is+required");
                return;
            }

            if (positionStr == null || positionStr.trim().isEmpty()) {
                positionStr = String.valueOf(bannerDao.getNextDisplayOrder());
            }

            int position = Integer.parseInt(positionStr);

            // Get admin ID from session
            HttpSession session = request.getSession(false);
            Integer adminId = SessionUtil.getUserId(session);

            if (adminId == null) {
                response.sendRedirect("index.jsp");
                return;
            }

            // Handle file upload
            Part filePart = request.getPart("bannerImage");
            if (filePart == null || filePart.getSize() == 0) {
                response.sendRedirect("manage_banner.jsp?error=No+file+selected");
                return;
            }

            // Validate file type
            String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String fileExtension = "";
            int dotIndex = fileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = fileName.substring(dotIndex + 1).toLowerCase();
            }

            if (!Arrays.asList("jpg", "jpeg", "png", "gif", "webp").contains(fileExtension)) {
                response.sendRedirect("manage_banner.jsp?error=Invalid+file+type.+Only+JPG,+JPEG,+PNG,+GIF,+WEBP+allowed");
                return;
            }

            // Validate file size (5MB max)
            if (filePart.getSize() > 5 * 1024 * 1024) {
                response.sendRedirect("manage_banner.jsp?error=File+size+exceeds+5MB");
                return;
            }

            // Save file - DIPERBAIKI mengikut contoh RegistrationServlet
            String savedFilePath = saveBannerImage(filePart, request);
            if (savedFilePath == null) {
                response.sendRedirect("manage_banner.jsp?error=Error+saving+file");
                return;
            }

            // Prepare banner data
            Map<String, Object> bannerData = new HashMap<>();
            bannerData.put("title", title);
            bannerData.put("description", ""); // Original description field
            bannerData.put("imagePath", savedFilePath);
            bannerData.put("fileName", fileName);
            bannerData.put("fileSize", filePart.getSize());
            bannerData.put("displayOrder", position);
            bannerData.put("caption", caption);
            bannerData.put("imageDimensions", "1920x400"); // Default dimensions
            bannerData.put("status", "visible".equals(active) ? "visible" : "hidden");
            bannerData.put("createdBy", adminId);
            bannerData.put("createdAt", new Timestamp(System.currentTimeMillis()));

            // Add to database
            int bannerId = bannerDao.addBanner(bannerData);

            if (bannerId > 0) {
                // Reorder other banners if needed
                reorderBannersAfterInsert(position, bannerId);

                response.sendRedirect("manage_banner.jsp?success=Banner+uploaded+successfully");
            } else {
                // Delete the uploaded file since DB insert failed
                deleteBannerFile(savedFilePath, request);
                response.sendRedirect("manage_banner.jsp?error=Error+saving+to+database");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error adding banner", e);
            response.sendRedirect("manage_banner.jsp?error="
                    + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
        }
    }

    private void updateCaption(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        try {
            String bannerIdStr = request.getParameter("banner_id");
            String caption = request.getParameter("caption");

            if (bannerIdStr == null || bannerIdStr.trim().isEmpty()) {
                out.write("{\"status\":\"error\",\"message\":\"Banner ID required\"}");
                return;
            }

            int bannerId = Integer.parseInt(bannerIdStr);

            boolean success = bannerDao.updateBannerCaption(bannerId, caption);

            if (success) {
                out.write("{\"status\":\"success\"}");
            } else {
                out.write("{\"status\":\"error\",\"message\":\"Failed to update caption\"}");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error updating caption", e);
            out.write("{\"status\":\"error\",\"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        } finally {
            out.close();
        }
    }

    private void updateStatus(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        try {
            String bannerIdStr = request.getParameter("banner_id");
            String status = request.getParameter("status");

            if (bannerIdStr == null || bannerIdStr.trim().isEmpty()) {
                out.write("{\"status\":\"error\",\"message\":\"Banner ID required\"}");
                return;
            }

            int bannerId = Integer.parseInt(bannerIdStr);

            boolean success = bannerDao.updateBannerStatus(bannerId, status);

            if (success) {
                out.write("{\"status\":\"success\"}");
            } else {
                out.write("{\"status\":\"error\",\"message\":\"Failed to update status\"}");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error updating status", e);
            out.write("{\"status\":\"error\",\"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        } finally {
            out.close();
        }
    }

    private void updateOrder(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        try {
            String bannerIdStr = request.getParameter("banner_id");
            String orderStr = request.getParameter("order");

            if (bannerIdStr == null || bannerIdStr.trim().isEmpty()
                    || orderStr == null || orderStr.trim().isEmpty()) {
                out.write("{\"status\":\"error\",\"message\":\"Banner ID and order required\"}");
                return;
            }

            int bannerId = Integer.parseInt(bannerIdStr);
            int displayOrder = Integer.parseInt(orderStr);

            boolean success = bannerDao.updateBannerOrder(bannerId, displayOrder);

            if (success) {
                out.write("{\"status\":\"success\"}");
            } else {
                out.write("{\"status\":\"error\",\"message\":\"Failed to update order\"}");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error updating order", e);
            out.write("{\"status\":\"error\",\"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        } finally {
            out.close();
        }
    }

    private void saveAllOrders(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        try {
            String[] bannerIds = request.getParameterValues("banner_ids[]");

            if (bannerIds == null || bannerIds.length == 0) {
                out.write("{\"status\":\"error\",\"message\":\"No banners provided\"}");
                return;
            }

            List<Integer> ids = new ArrayList<>();
            for (String id : bannerIds) {
                try {
                    ids.add(Integer.parseInt(id));
                } catch (NumberFormatException e) {
                    out.write("{\"status\":\"error\",\"message\":\"Invalid banner ID: " + id + "\"}");
                    return;
                }
            }

            boolean success = bannerDao.updateAllBannerOrders(ids);

            if (success) {
                out.write("{\"status\":\"success\"}");
            } else {
                out.write("{\"status\":\"error\",\"message\":\"Failed to save banner orders\"}");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error saving all orders", e);
            out.write("{\"status\":\"error\",\"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
        } finally {
            out.close();
        }
    }

    private void deleteBanner(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            String bannerIdStr = request.getParameter("banner_id");

            if (bannerIdStr == null || bannerIdStr.trim().isEmpty()) {
                response.sendRedirect("manage_banner.jsp?error=Banner+ID+required");
                return;
            }

            int bannerId = Integer.parseInt(bannerIdStr);

            // Get banner to delete file
            Map<String, Object> banner = bannerDao.getBannerByIdWithDetails(bannerId);
            if (banner != null && banner.get("imagePath") != null) {
                String imagePath = (String) banner.get("imagePath");
                if (imagePath != null && !imagePath.isEmpty()) {
                    // Delete file first
                    deleteBannerFile(imagePath, request);
                }
            }

            // Delete from database
            boolean success = bannerDao.deleteBanner(bannerId);

            if (success) {
                response.sendRedirect("manage_banner.jsp?success=Banner+deleted+successfully");
            } else {
                response.sendRedirect("manage_banner.jsp?error=Error+deleting+banner");
            }

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error deleting banner", e);
            response.sendRedirect("manage_banner.jsp?error="
                    + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
        }
    }

    /**
     * Save banner image - DIPERBAIKI berdasarkan contoh RegistrationServlet
     */
    private String saveBannerImage(Part filePart, HttpServletRequest request) throws IOException {
        if (filePart == null || filePart.getSize() == 0 || filePart.getSubmittedFileName() == null) {
            logger.info("No file uploaded or empty file");
            return null;
        }

        try {
            // Dapatkan application context path
            ServletContext context = request.getServletContext();

            // === DEBUG LOGGING ===
            logger.info("=== BANNER FILE UPLOAD DEBUG START ===");
            logger.info("Original filename: " + filePart.getSubmittedFileName());
            logger.info("File size: " + filePart.getSize() + " bytes");

            // Path untuk folder banner (sama seperti profile_picture)
            String folderName = "banner";

            // Path untuk simpan dalam webapp (untuk access via browser)
            String webappPath = context.getRealPath("");
            if (webappPath == null) {
                webappPath = "";
            }

            // FIX PATH: Tambah separator yang betul
            String fullWebappPath = webappPath;
            if (!fullWebappPath.endsWith(File.separator)) {
                fullWebappPath += File.separator;
            }
            fullWebappPath += folderName + File.separator;

            // Path untuk simpan dalam source project (untuk development)
            String projectPath = "";
            try {
                // Build path mengikut struktur project
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile(); // build folder
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile(); // project root
                    if (projectRoot != null) {
                        projectPath = projectRoot.getAbsolutePath()
                                + File.separator + "web"
                                + File.separator + folderName
                                + File.separator;
                    }
                }
            } catch (Exception e) {
                logger.log(Level.WARNING, "Could not build project path: " + e.getMessage());
                projectPath = fullWebappPath; // fallback
            }

            logger.info("Webapp Path: " + fullWebappPath);
            logger.info("Project Path: " + projectPath);

            // Buat directory untuk kedua-dua lokasi
            File webappDir = new File(fullWebappPath);
            File projectDir = new File(projectPath);

            if (!webappDir.exists()) {
                boolean created = webappDir.mkdirs();
                logger.info("Created webapp directory: " + created);
            }

            if (!projectDir.exists()) {
                boolean created = projectDir.mkdirs();
                logger.info("Created project directory: " + created);
            }

            // Generate unique filename
            String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String fileExtension = "";

            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex).toLowerCase();
            }

            // Generate unique name seperti dalam RegistrationServlet
            // Sanitize filename untuk keselamatan
            String sanitizedName = originalFileName.substring(0, dotIndex > 0 ? dotIndex : originalFileName.length())
                    .replaceAll("[^a-zA-Z0-9._-]", "_");

            String fileName = sanitizedName + "_" + System.currentTimeMillis() + fileExtension;
            logger.info("Generated filename: " + fileName);

            // === SAVE TO BOTH LOCATIONS ===
            String webappFilePath = fullWebappPath + fileName;
            String projectFilePath = projectPath + fileName;

            // Gunakan method yang sama seperti RegistrationServlet
            boolean filesSaved = saveFileToMultipleLocations(filePart, webappFilePath, projectFilePath);

            logger.info("Files saved successfully: " + filesSaved);

            // Debug: Check if files exist
            File webappFile = new File(webappFilePath);
            File projectFile = new File(projectFilePath);

            logger.info("Webapp file exists: " + webappFile.exists() + ", size: "
                    + (webappFile.exists() ? webappFile.length() : 0) + " bytes");
            logger.info("Project file exists: " + projectFile.exists() + ", size: "
                    + (projectFile.exists() ? projectFile.length() : 0) + " bytes");

            logger.info("=== BANNER FILE UPLOAD DEBUG END ===");

            // Return relative path untuk database (sama seperti profile_picture)
            return folderName + "/" + fileName;

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error in saveBannerImage method", e);
            return null;
        }
    }

    /**
     * Helper method untuk save file ke multiple locations - SAMA seperti
     * RegistrationServlet
     */
    private boolean saveFileToMultipleLocations(Part filePart, String... filePaths) throws IOException {
        try (InputStream input = filePart.getInputStream()) {
            // Read all data first
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = input.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }
            byte[] fileData = baos.toByteArray();

            logger.info("File data read: " + fileData.length + " bytes");

            // Write to each location
            boolean allSuccess = true;
            for (String filePath : filePaths) {
                try (FileOutputStream output = new FileOutputStream(filePath)) {
                    output.write(fileData);
                    logger.info("Saved to: " + filePath);
                } catch (IOException e) {
                    logger.log(Level.WARNING, "Failed to save to: " + filePath, e);
                    allSuccess = false;
                }
            }
            return allSuccess;
        }
    }

    /**
     * Delete banner file - DIPERBAIKI berdasarkan contoh ProfileServlet
     */
    private void deleteBannerFile(String filePath, HttpServletRequest request) {
        if (filePath == null || filePath.isEmpty()) {
            return;
        }

        try {
            ServletContext context = request.getServletContext();
            String webappPath = context.getRealPath("");

            if (webappPath == null) {
                webappPath = "";
            }

            // Build webapp full path
            String webappFullPath = webappPath + File.separator + filePath;

            // Build project path (sama seperti dalam saveBannerImage)
            String projectPath = "";
            try {
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile();
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile();
                    if (projectRoot != null) {
                        projectPath = projectRoot.getAbsolutePath()
                                + File.separator + "web"
                                + File.separator + filePath;
                    }
                }
            } catch (Exception e) {
                logger.log(Level.WARNING, "Could not build project path for deletion: " + e.getMessage());
                projectPath = webappFullPath;
            }

            // Delete from webapp location
            File webappFile = new File(webappFullPath);
            if (webappFile.exists()) {
                boolean deleted = webappFile.delete();
                logger.info("Deleted webapp file: " + webappFullPath + ", Success: " + deleted);
            } else {
                logger.warning("Webapp file not found: " + webappFullPath);
            }

            // Delete from project location
            File projectFile = new File(projectPath);
            if (projectFile.exists()) {
                boolean deleted = projectFile.delete();
                logger.info("Deleted project file: " + projectPath + ", Success: " + deleted);
            } else {
                logger.warning("Project file not found: " + projectPath);
            }

        } catch (Exception e) {
            logger.log(Level.WARNING, "Error deleting banner file", e);
        }
    }

    private void reorderBannersAfterInsert(int newPosition, int newBannerId) {
        try {
            // Get all banners except the new one
            List<Map<String, Object>> allBanners = bannerDao.getAllBannersWithDetails();

            // Filter out the new banner
            List<Map<String, Object>> otherBanners = new ArrayList<>();
            for (Map<String, Object> banner : allBanners) {
                if ((Integer) banner.get("bannerId") != newBannerId) {
                    otherBanners.add(banner);
                }
            }

            // Update display orders
            int order = 1;
            for (Map<String, Object> banner : otherBanners) {
                if (order == newPosition) {
                    order++; // Skip the new position for the new banner
                }
                int bannerId = (Integer) banner.get("bannerId");
                bannerDao.updateBannerOrder(bannerId, order);
                order++;
            }

            // Update the new banner's order
            bannerDao.updateBannerOrder(newBannerId, newPosition);

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error reordering banners", e);
        }
    }
}
