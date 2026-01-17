<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.UsersDao" %>
<%@ page import="com.rimba.adopt.util.DatabaseConnection" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
// Check if user is logged in and is admin
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isAdmin(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Initialize variables - USING OLD JAVA SYNTAX (no diamond operator)
    Map<String, Integer> stats = new HashMap<String, Integer>();
    List<Map<String, Object>> recentAdopters = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> recentShelters = new ArrayList<Map<String, Object>>();
    int[] adopterTrends = new int[12];
    int[] shelterTrends = new int[12];

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");

    Connection conn = null;
    java.sql.PreparedStatement pstmt = null;
    java.sql.ResultSet rs = null;

    try {
        conn = DatabaseConnection.getConnection();
        UsersDao usersDao = new UsersDao(conn);

        // === GET TOTAL USERS ===
        String totalUsersSql = "SELECT COUNT(*) as count FROM users WHERE role IN ('adopter', 'shelter')";
        pstmt = conn.prepareStatement(totalUsersSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("totalUsers", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET TODAY'S REGISTRATIONS ===
        String todaySql = "SELECT COUNT(*) as count FROM users WHERE DATE(created_at) = CURRENT_DATE AND role IN ('adopter', 'shelter')";
        pstmt = conn.prepareStatement(todaySql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("todayRegistrations", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET ADOPTER REGISTRATIONS ===
        String adopterSql = "SELECT COUNT(*) as count FROM users WHERE role = 'adopter'";
        pstmt = conn.prepareStatement(adopterSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("adopterRegistrations", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET SHELTER REGISTRATIONS ===
        String shelterSql = "SELECT COUNT(*) as count FROM users WHERE role = 'shelter'";
        pstmt = conn.prepareStatement(shelterSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("shelterRegistrations", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET PENDING SHELTER APPROVALS ===
        String pendingSql = "SELECT COUNT(*) as count FROM shelter WHERE approval_status = 'pending'";
        pstmt = conn.prepareStatement(pendingSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("pendingApprovals", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();
        

        // === GET MONTHLY REGISTRATIONS ===
        String monthlySql = "SELECT COUNT(*) as count FROM users WHERE MONTH(created_at) = MONTH(CURRENT_DATE) AND YEAR(created_at) = YEAR(CURRENT_DATE) AND role IN ('adopter', 'shelter')";
        pstmt = conn.prepareStatement(monthlySql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("monthlyRegistrations", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET VERIFIED USERS ===
        String verifiedSql = "SELECT COUNT(*) as count FROM users u "
                + "LEFT JOIN shelter s ON u.user_id = s.shelter_id "
                + "WHERE (u.role = 'adopter') OR "
                + "(u.role = 'shelter' AND s.approval_status = 'approved')";
        pstmt = conn.prepareStatement(verifiedSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("verifiedUsers", rs.getInt("count"));
        }

        // === GET APPROVED SHELTERS ===
        String approvedShelterSql = "SELECT COUNT(*) as count FROM shelter WHERE approval_status = 'approved'";
        pstmt = conn.prepareStatement(approvedShelterSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("approvedShelters", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

        // === GET REGISTRATION TRENDS (12 months) ===
        String trendsSql = "SELECT MONTH(u.created_at) as month, u.role, COUNT(*) as count "
                + "FROM users u "
                + "WHERE YEAR(u.created_at) = YEAR(CURRENT_DATE) AND u.role IN ('adopter', 'shelter') "
                + "GROUP BY MONTH(u.created_at), u.role "
                + "ORDER BY month";

        pstmt = conn.prepareStatement(trendsSql);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            int month = rs.getInt("month") - 1; // Convert to 0-based index
            String role = rs.getString("role");
            int count = rs.getInt("count");

            if ("adopter".equals(role)) {
                adopterTrends[month] = count;
            } else if ("shelter".equals(role)) {
                shelterTrends[month] = count;
            }
        }
        rs.close();
        pstmt.close();

        // === GET RECENT ADOPTER REGISTRATIONS (latest 15) ===
        String recentAdopterSql = "SELECT u.user_id, u.name, u.email, u.created_at, 'adopter' as role "
                + "FROM users u "
                + "WHERE u.role = 'adopter' "
                + "ORDER BY u.created_at DESC "
                + "FETCH FIRST 15 ROWS ONLY";

        pstmt = conn.prepareStatement(recentAdopterSql);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, Object> adopter = new HashMap<String, Object>();
            adopter.put("id", "USR-" + rs.getInt("user_id"));
            adopter.put("name", rs.getString("name"));
            adopter.put("email", rs.getString("email"));
            adopter.put("date", sdf.format(rs.getTimestamp("created_at")));
            adopter.put("status", "Verified");
            adopter.put("statusColor", "#6DBF89");
            adopter.put("statusText", "#06321F");
            recentAdopters.add(adopter);
        }
        rs.close();
        pstmt.close();

        // === GET RECENT SHELTER REGISTRATIONS (latest 12) ===
        String recentShelterSql = "SELECT u.user_id, u.name, u.email, u.created_at, s.approval_status "
                + "FROM users u "
                + "LEFT JOIN shelter s ON u.user_id = s.shelter_id "
                + "WHERE u.role = 'shelter' "
                + "ORDER BY u.created_at DESC "
                + "FETCH FIRST 12 ROWS ONLY";

        pstmt = conn.prepareStatement(recentShelterSql);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, Object> shelter = new HashMap<String, Object>();
            shelter.put("id", "SHT-" + rs.getInt("user_id"));
            shelter.put("name", rs.getString("name"));
            shelter.put("email", rs.getString("email"));
            shelter.put("date", sdf.format(rs.getTimestamp("created_at")));

            String approvalStatus = rs.getString("approval_status");
            // UBAH BAHAGIAN NI - hanya 3 status
            if ("approved".equals(approvalStatus)) {
                shelter.put("status", "Approved");
                shelter.put("statusColor", "#6DBF89");
                shelter.put("statusText", "#06321F");
            } else if ("rejected".equals(approvalStatus)) {
                shelter.put("status", "Rejected");
                shelter.put("statusColor", "#B84A4A");
                shelter.put("statusText", "#FFFFFF");
            } else {
                // Default: pending or null
                shelter.put("status", "Pending");
                shelter.put("statusColor", "#C49A6C");
                shelter.put("statusText", "#FFFFFF");
            }
            recentShelters.add(shelter);
        }

        // === GET PENDING VERIFICATION ===
        String pendingVerificationSql = "SELECT COUNT(*) as count FROM users u LEFT JOIN shelter s ON u.user_id = s.shelter_id WHERE u.role = 'shelter' AND (s.approval_status IS NULL OR s.approval_status = 'pending')";
        pstmt = conn.prepareStatement(pendingVerificationSql);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            stats.put("pendingVerification", rs.getInt("count"));
        }
        rs.close();
        pstmt.close();

    } catch (Exception e) {
        e.printStackTrace();
        // Set default values if error
        stats.put("totalUsers", 0);
        stats.put("todayRegistrations", 0);
        stats.put("adopterRegistrations", 0);
        stats.put("shelterRegistrations", 0);
        stats.put("pendingApprovals", 0);
        stats.put("monthlyRegistrations", 0);
        stats.put("verifiedUsers", 0);
        stats.put("approvedShelters", 0);
        stats.put("pendingVerification", 0);
    } finally {
        // Manual resource cleanup (no try-with-resources)
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (Exception e) {
        }
        try {
            if (pstmt != null) {
                pstmt.close();
            }
        } catch (Exception e) {
        }
        try {
            if (conn != null) {
                conn.close();
            }
        } catch (Exception e) {
        }
    }

    // Convert arrays to JSON for JavaScript
    String adopterTrendsJson = java.util.Arrays.toString(adopterTrends);
    String shelterTrendsJson = java.util.Arrays.toString(shelterTrends);

    // Calculate verification rate
    int totalUsersForRate = stats.containsKey("totalUsers") ? stats.get("totalUsers") : 1;
    int verifiedUsersForRate = stats.containsKey("verifiedUsers") ? stats.get("verifiedUsers") : 0;
    int verificationRate = totalUsersForRate > 0 ? (verifiedUsersForRate * 100 / totalUsersForRate) : 0;
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Admin Dashboard - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
        <style>
            .banner-slide {
                display: none;
                animation: slideIn 0.5s ease-in-out;
            }
            .banner-slide.active {
                display: block;
            }
            @keyframes slideIn {
                from {
                    opacity: 0;
                    transform: translateX(100%);
                }
                to {
                    opacity: 1;
                    transform: translateX(0);
                }
            }
            .dot {
                height: 12px;
                width: 12px;
                margin: 0 4px;
                background-color: rgba(255, 255, 255, 0.5);
                border-radius: 50%;
                display: inline-block;
                transition: background-color 0.3s ease;
                cursor: pointer;
            }
            .dot.active {
                background-color: #FFFFFF;
            }

            .pagination-btn {
                padding: 6px 12px;
                margin: 0 2px;
                border-radius: 4px;
                background-color: #F6F3E7;
                color: #2B2B2B;
                border: 1px solid #E5E5E5;
                cursor: pointer;
                transition: all 0.3s ease;
            }

            .pagination-btn:hover {
                background-color: #E5E5E5;
            }

            .pagination-btn.active {
                background-color: #2F5D50;
                color: #FFFFFF;
                border-color: #2F5D50;
            }

            .pagination-btn:disabled {
                opacity: 0.5;
                cursor: not-allowed;
            }

            .registration-card {
                border: 1px solid #E5E5E5;
                border-radius: 0.75rem;
                overflow: hidden;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
                height: 100%;
                display: flex;
                flex-direction: column;
            }

            .registration-header {
                background-color: #F6F3E7;
                padding: 1rem 1.5rem;
                border-bottom: 1px solid #E5E5E5;
            }

            .registration-body {
                flex: 1;
                overflow: hidden;
                display: flex;
                flex-direction: column;
            }

            .registration-table-container {
                flex: 1;
                overflow-y: auto;
                max-height: 400px;
            }

            .quick-link-icon {
                transition: transform 0.2s ease;
            }

            .quick-link:hover .quick-link-icon {
                transform: translateX(3px);
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Banner slideshow section -->
        <div class="p-4 pt-6 relative z-10 flex justify-center items-start">
            <div class="w-full" style="max-width: 1450px;">
                <div class="relative overflow-hidden rounded-xl shadow-lg">
                    <!-- Banner Images - Get from database -->
                    <div class="banner-container relative" style="height: 400px;">
                        <%
                            Connection bannerConn = null;
                            java.sql.PreparedStatement bannerPstmt = null;
                            java.sql.ResultSet bannerRs = null;
                            try {
                                bannerConn = DatabaseConnection.getConnection();
                                String bannerSql = "SELECT image_path FROM awareness_banner WHERE status = 'visible' ORDER BY COALESCE(display_order, 999) ASC";
                                bannerPstmt = bannerConn.prepareStatement(bannerSql);
                                bannerRs = bannerPstmt.executeQuery();

                                int bannerIndex = 0;
                                while (bannerRs.next()) {
                                    String imagePath = bannerRs.getString("image_path");
                                    if (imagePath != null && !imagePath.isEmpty()) {
                        %>
                        <div class="banner-slide <%= bannerIndex == 0 ? "active" : ""%>">
                            <img src="<%= imagePath%>" alt="Banner <%= bannerIndex + 1%>" class="w-full h-full object-cover">
                        </div>
                        <%
                                    bannerIndex++;
                                }
                            }

                            // If no banners in database, use static defaults
                            if (bannerIndex == 0) {
                        %>
                        <div class="banner-slide active">
                            <img src="banner/banner1.jpg" alt="Banner 1" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner2.jpg" alt="Banner 2" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner3.jpg" alt="Banner 3" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner4.jpg" alt="Banner 4" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner5.jpg" alt="Banner 5" class="w-full h-full object-cover">
                        </div>
                        <%
                            }
                        } catch (Exception e) {
                            // Fallback to static banners if error
                        %>
                        <div class="banner-slide active">
                            <img src="banner/banner1.jpg" alt="Banner 1" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner2.jpg" alt="Banner 2" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner3.jpg" alt="Banner 3" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner4.jpg" alt="Banner 4" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner5.jpg" alt="Banner 5" class="w-full h-full object-cover">
                        </div>
                        <%
                            } finally {
                                try {
                                    if (bannerRs != null) {
                                        bannerRs.close();
                                    }
                                } catch (Exception e) {
                                }
                                try {
                                    if (bannerPstmt != null) {
                                        bannerPstmt.close();
                                    }
                                } catch (Exception e) {
                                }
                                try {
                                    if (bannerConn != null) {
                                        bannerConn.close();
                                    }
                                } catch (Exception e) {
                                }
                            }
                        %>

                        <!-- Navigation Arrows -->
                        <button onclick="changeSlide( - 1)" class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                            </svg>
                        </button>
                        <button onclick="changeSlide(1)" class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                            </svg>
                        </button>
                    </div>

                    <!-- Dots Indicator -->
                    <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex items-center justify-center" id="dotsContainer">
                        <!-- Dots will be generated by JavaScript -->
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Dashboard Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Dashboard Title -->
                <div class="mb-8 pb-4 border-b border-[#E5E5E5]">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Admin Dashboard</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">
                        Manage user registrations, shelter approvals, and monitor system activities.
                    </p>
                </div>

                <!-- Registration Statistics Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
                    <!-- Total Users -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium" style="color: #2F5D50;">Total Users</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("totalUsers") ? stats.get("totalUsers") : 0%></p>
                        <p class="text-xs text-gray-500 mt-1">
                            <%= stats.containsKey("adopterRegistrations") ? stats.get("adopterRegistrations") : 0%> adopters, 
                            <%= stats.containsKey("shelterRegistrations") ? stats.get("shelterRegistrations") : 0%> shelters
                        </p>
                    </div>

                    <!-- New Registrations (Today) -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#57A677]">
                        <p class="text-sm font-medium" style="color: #57A677;">Today's Registrations</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("todayRegistrations") ? stats.get("todayRegistrations") : 0%></p>
                        <%
                            // Estimate today's adopters and shelters
                            int todayTotal = stats.containsKey("todayRegistrations") ? stats.get("todayRegistrations") : 0;
                            int todayAdopters = (int) (todayTotal * 0.8);
                            int todayShelters = (int) (todayTotal * 0.2);
                        %>
                        <p class="text-xs text-gray-500 mt-1"><%= todayAdopters%> adopters, <%= todayShelters%> shelters</p>
                    </div>

                    <!-- Pending Shelter Approvals -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <p class="text-sm font-medium" style="color: #C49A6C;">Pending Approvals</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;">
                            <%= stats.containsKey("pendingApprovals") ? stats.get("pendingApprovals") : 0%>
                        </p>
                        <p class="text-xs text-gray-500 mt-1">Shelters awaiting review</p>
                    </div>

                    <!-- Monthly Registrations -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <p class="text-sm font-medium" style="color: #57A677;">This Month</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("monthlyRegistrations") ? stats.get("monthlyRegistrations") : 0%></p>
                        <p class="text-xs text-gray-500 mt-1">New registrations</p>
                    </div>

                    <!-- Verified Users -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium" style="color: #2F5D50;">Verified Users</p>
                        <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("verifiedUsers") ? stats.get("verifiedUsers") : 0%></p>
                        <p class="text-xs text-gray-500 mt-1"><%= verificationRate%>% verification rate</p>
                    </div>
                </div>

                <!-- Registration Trends Chart -->
                <div class="border border-[#E5E5E5] rounded-xl p-6 mb-8 shadow-sm">
                    <h2 class="text-xl font-semibold" style="color: #2B2B2B;">Registration Trends</h2>
                    <div class="relative" style="height: 400px;">
                        <canvas id="registrationTrendsChart"></canvas>
                    </div>
                </div>

                <!-- System Overview & Registration Management -->
                <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 mb-8">
                    <!-- Left area: Registration Stats -->
                    <div class="lg:col-span-3 flex flex-col gap-6">
                        <!-- Registration Type Stats -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="bg-[#E8F5EE] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                                <p class="text-sm font-medium" style="color: #57A677;">Adopter Registrations</p>
                                <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("adopterRegistrations") ? stats.get("adopterRegistrations") : 0%></p>
                                <p class="text-xs text-gray-500 mt-1">Active adopters in system</p>
                            </div>

                            <div class="bg-[#F5F0EB] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                                <p class="text-sm font-medium" style="color: #C49A6C;">Shelter Registrations</p>
                                <p class="text-3xl font-bold" style="color: #2B2B2B;"><%= stats.containsKey("shelterRegistrations") ? stats.get("shelterRegistrations") : 0%></p>
                                <p class="text-xs text-gray-500 mt-1">
                                    <%= stats.containsKey("approvedShelters") ? stats.get("approvedShelters") : 0%> approved, 
                                    <%= stats.containsKey("pendingApprovals") ? stats.get("pendingApprovals") : 0%> pending
                                </p>
                            </div>
                        </div>

                        <!-- Registration Status Chart -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm bg-white">
                            <h2 class="text-xl font-semibold" style="color: #2B2B2B;">Registration Status Overview</h2>
                            <div class="relative w-full h-72 sm:h-80 lg:h-[350px]">
                                <canvas id="registrationStatusChart" class="w-full h-full"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Links (right column) -->
                    <div class="lg:col-span-1 border border-[#E5E5E5] rounded-xl p-6 shadow-sm flex flex-col h-full">
                        <div class="flex items-center justify-between mb-4">
                            <h2 class="text-xl font-semibold" style="color: #2B2B2B;">Quick Actions</h2>
                            <span class="text-xs px-2 py-1 rounded-full" style="background-color: #2F5D50; color: #FFFFFF;">
                                2 Actions
                            </span>
                        </div>

                        <!-- Container untuk action links dengan scroll -->
                        <div class="flex-1 overflow-y-auto mb-4">
                            <div class="space-y-6">
                                <!-- Manage Banner -->
                                <a href="ManageBannerServlet" class="flex items-center gap-3 p-3 rounded-lg text-white hover:bg-[#24483E] transition group w-full quick-link" style="background-color: #2F5D50;">
                                    <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background-color: rgba(255, 255, 255, 0.2);">
                                        <svg class="w-5 h-5 quick-link-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                              d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                                        </svg>
                                    </div>
                                    <div class="flex-1">
                                        <span class="text-sm font-medium block">Manage Banner</span>
                                        <span class="text-xs opacity-80">Update homepage banners</span>
                                    </div>
                                    <svg class="w-4 h-4 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                                    </svg>
                                </a>

                                <!-- Approve Registrations -->
                                <a href="review_registrations.jsp" class="flex items-center gap-3 p-3 rounded-lg text-white hover:bg-[#24483E] transition group w-full quick-link" style="background-color: #2F5D50;">
                                    <div class="w-10 h-10 rounded-lg flex items-center justify-center" style="background-color: rgba(255, 255, 255, 0.2);">
                                        <svg class="w-5 h-5 quick-link-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                              d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                                        </svg>
                                    </div>
                                    <div class="flex-1">
                                        <span class="text-sm font-medium block">Review Registrations</span>
                                        <span class="text-xs opacity-80">Review & approve users</span>
                                    </div>
                                    <svg class="w-4 h-4 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                                    </svg>
                                </a>
                            </div>
                        </div>

                        <!-- Quick Tips Section - selalu di bawah -->
                        <div class="mt-auto">
                            <div class="p-4 rounded-lg" style="background-color: #24483E;">
                                <div class="flex items-center gap-2 mb-2">
                                    <svg class="w-4 h-4 text-[#6DBF89]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                    </svg>
                                    <span class="text-xs font-medium text-white">Quick Tips</span>
                                </div>
                                <p class="text-xs text-white opacity-80">
                                    Only essential actions are shown. Use the main menu for complete admin controls.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Recent Registration Activities - Side by Side -->
                <div class="mb-8">
                    <div class="flex justify-between items-center mb-6">
                        <h2 class="text-2xl font-bold" style="color: #2B2B2B;">Recent Registration Activities</h2>
                        <a href="review_registrations.jsp" class="text-sm hover:text-[#24483E] font-medium" style="color: #2F5D50;">
                            View All Registrations →
                        </a>
                    </div>

                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <!-- Adopter Registrations Card -->
                        <div class="registration-card">
                            <div class="registration-header">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                        <div class="w-10 h-10 rounded-full flex items-center justify-center" style="background-color: #6DBF89;">
                                            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                            </svg>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-lg" style="color: #2B2B2B;">Adopter Registrations</h3>
                                            <p class="text-sm text-gray-500">Latest adopter sign-ups</p>
                                        </div>
                                    </div>
                                    <span class="px-3 py-1 text-sm rounded-full" style="background-color: #2F5D50; color: #FFFFFF;">
                                        Total: <%= recentAdopters.size()%>
                                    </span>
                                </div>
                            </div>

                            <div class="registration-body">
                                <div class="registration-table-container">
                                    <table class="w-full">
                                        <thead class="sticky top-0 z-10" style="background-color: #F6F3E7;">
                                            <tr class="border-b border-[#E5E5E5]">
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">User</th>
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Date</th>
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Status</th>                                            </tr>
                                        </thead>
                                        <tbody id="adopterTableBody">
                                            <!-- Adopter rows akan diisi oleh JavaScript -->
                                        </tbody>
                                    </table>
                                </div>

                                <!-- Adopter Pagination -->
                                <div class="flex justify-between items-center p-4 border-t border-[#E5E5E5]">
                                    <div class="text-sm" style="color: #2B2B2B;">
                                        Showing <span id="adopterStart">1</span> to <span id="adopterEnd">5</span> of <span id="adopterTotal"><%= recentAdopters.size()%></span> entries
                                    </div>
                                    <div class="flex items-center space-x-1" id="adopterPagination">
                                        <!-- Pagination buttons akan diisi oleh JavaScript -->
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Shelter Registrations Card -->
                        <div class="registration-card">
                            <div class="registration-header">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                        <div class="w-10 h-10 rounded-full flex items-center justify-center" style="background-color: #C49A6C;">
                                            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
                                            </svg>
                                        </div>
                                        <div>
                                            <h3 class="font-semibold text-lg" style="color: #2B2B2B;">Shelter Registrations</h3>
                                            <p class="text-sm text-gray-500">Latest shelter applications</p>
                                        </div>
                                    </div>
                                    <span class="px-3 py-1 text-sm rounded-full" style="background-color: #2F5D50; color: #FFFFFF;">
                                        Total: <%= recentShelters.size()%>
                                    </span>
                                </div>
                            </div>

                            <div class="registration-body">
                                <div class="registration-table-container">
                                    <table class="w-full">
                                        <thead class="sticky top-0 z-10" style="background-color: #F6F3E7;">
                                            <tr class="border-b border-[#E5E5E5]">
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Shelter</th>
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Date</th>
                                                <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Status</th>
                                            </tr>
                                        </thead>
                                        <tbody id="shelterTableBody">
                                            <!-- Shelter rows akan diisi oleh JavaScript -->
                                        </tbody>
                                    </table>
                                </div>

                                <!-- Shelter Pagination -->
                                <div class="flex justify-between items-center p-4 border-t border-[#E5E5E5]">
                                    <div class="text-sm" style="color: #2B2B2B;">
                                        Showing <span id="shelterStart">1</span> to <span id="shelterEnd">5</span> of <span id="shelterTotal"><%= recentShelters.size()%></span> entries
                                    </div>
                                    <div class="flex items-center space-x-1" id="shelterPagination">
                                        <!-- Pagination buttons akan diisi oleh JavaScript -->
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
                            // Banner Slideshow
                            let slideIndex = 1;
                            let slideTimer;
                            function showSlides(n) {
                            let slides = document.getElementsByClassName("banner-slide");
                            let dots = document.getElementsByClassName("dot");
                            if (n > slides.length) {
                            slideIndex = 1
                            }
                            if (n < 1) {
                            slideIndex = slides.length
                            }

                            for (let i = 0; i < slides.length; i++) {
                            slides[i].classList.remove("active");
                            }
                            for (let i = 0; i < dots.length; i++) {
                            dots[i].classList.remove("active");
                            }

                            if (slides.length > 0) {
                            slides[slideIndex - 1].classList.add("active");
                            if (dots.length > 0) {
                            dots[slideIndex - 1].classList.add("active");
                            }
                            }
                            }

                            function changeSlide(n) {
                            clearInterval(slideTimer);
                            showSlides(slideIndex += n);
                            startAutoSlide();
                            }

                            function currentSlide(n) {
                            clearInterval(slideTimer);
                            showSlides(slideIndex = n);
                            startAutoSlide();
                            }

                            function startAutoSlide() {
                            let slides = document.getElementsByClassName("banner-slide");
                            if (slides.length > 0) {
                            slideTimer = setInterval(() => {
                            slideIndex++;
                            showSlides(slideIndex);
                            }, 5000);
                            }
                            }

                            // Generate dots based on number of slides
                            function generateDots() {
                            let slides = document.getElementsByClassName("banner-slide");
                            let dotsContainer = document.getElementById("dotsContainer");
                            if (slides.length > 0 && dotsContainer) {
                            dotsContainer.innerHTML = '';
                            for (let i = 1; i <= slides.length; i++) {
                            let dot = document.createElement("span");
                            dot.className = i === 1 ? "dot active" : "dot";
                            dot.onclick = function() { currentSlide(i); };
                            dotsContainer.appendChild(dot);
                            }
                            }
                            }

                            // Initialize slideshow
                            document.addEventListener('DOMContentLoaded', function() {
                            generateDots();
                            showSlides(slideIndex);
                            startAutoSlide();
                            });
                            // Registration Trends Chart (Line Chart) - USING REAL DATA
                            const adopterTrends = <%= adopterTrendsJson%>;
                            const shelterTrends = <%= shelterTrendsJson%>;
                            const trendsCtx = document.getElementById('registrationTrendsChart').getContext('2d');
                            const registrationTrendsChart = new Chart(trendsCtx, {
                            type: 'line',
                                    data: {
                                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                                            datasets: [
                                            {
                                            label: 'Adopter Registrations',
                                                    data: adopterTrends,
                                                    borderColor: '#2F5D50',
                                                    backgroundColor: 'rgba(47, 93, 80, 0.1)',
                                                    borderWidth: 3,
                                                    tension: 0.4,
                                                    pointRadius: 4,
                                                    pointBackgroundColor: '#2F5D50',
                                                    fill: true
                                            },
                                            {
                                            label: 'Shelter Registrations',
                                                    data: shelterTrends,
                                                    borderColor: '#6DBF89',
                                                    backgroundColor: 'rgba(109, 191, 137, 0.1)',
                                                    borderWidth: 3,
                                                    tension: 0.4,
                                                    pointRadius: 4,
                                                    pointBackgroundColor: '#6DBF89',
                                                    fill: true
                                            }
                                            ]
                                    },
                                    options: {
                                    responsive: true,
                                            maintainAspectRatio: false,
                                            scales: {
                                            x: {
                                            grid: {
                                            display: false
                                            },
                                                    title: {
                                                    display: true,
                                                            text: 'Month'
                                                    }
                                            },
                                                    y: {
                                                    beginAtZero: true,
                                                            ticks: {
                                                            stepSize: 5
                                                            },
                                                            title: {
                                                            display: true,
                                                                    text: 'Number of Registrations'
                                                            }
                                                    }
                                            },
                                            plugins: {
                                            legend: {
                                            position: 'top'
                                            },
                                                    tooltip: {
                                                    mode: 'index',
                                                            intersect: false
                                                    }
                                            }
                                    }
                            });
                            // Registration Status Chart (Doughnut Chart) - USING REAL DATA
                            const verifiedUsers = <%= stats.containsKey("verifiedUsers") ? stats.get("verifiedUsers") : 0%>;
                            const pendingVerification = <%= stats.containsKey("pendingVerification") ? stats.get("pendingVerification") : 0%>;
                            const approvedShelters = <%= stats.containsKey("approvedShelters") ? stats.get("approvedShelters") : 0%>;
                            const pendingShelterReview = <%= stats.containsKey("pendingApprovals") ? stats.get("pendingApprovals") : 0%>;
                            const statusCtx = document.getElementById('registrationStatusChart').getContext('2d');
                            const registrationStatusChart = new Chart(statusCtx, {
                            type: 'doughnut',
                                    data: {
                                    labels: ['Verified Users', 'Pending Shelters', 'Approved Shelters', 'Rejected Shelter'],
                                            datasets: [{
                                            data: [
                                                    verifiedUsers,
                                                    pendingVerification,
                                                    approvedShelters,
                                                    pendingShelterReview
                                            ],
                                                    backgroundColor: [
                                                            '#6DBF89',
                                                            '#C49A6C',
                                                            '#2F5D50',
                                                            '#B84A4A'
                                                    ],
                                                    borderWidth: 2,
                                                    borderColor: '#ffffff'
                                            }]
                                    },
                                    options: {
                                    responsive: true,
                                            maintainAspectRatio: false,
                                            plugins: {
                                            legend: {
                                            position: 'right',
                                                    labels: {
                                                    boxWidth: 12,
                                                            padding: 15
                                                    }
                                            },
                                                    tooltip: {
                                                    callbacks: {
                                                    label: function (context) {
                                                    let label = context.label || '';
                                                    if (label) {
                                                    label += ': ';
                                                    }
                                                    const value = context.raw;
                                                    const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                                    const percentage = total > 0 ? Math.round((value / total) * 100) : 0;
                                                    label += value + ' (' + percentage + '%)';
                                                    return label;
                                                    }
                                                    }
                                                    }
                                            },
                                            cutout: '65%'
                                    }
                            });
                            // Sample Data for Adopter Registrations - USING REAL DATA FROM JSP
                            const adopterRegistrations = [
            <% for (int i = 0; i < recentAdopters.size(); i++) {
                    Map<String, Object> adopter = recentAdopters.get(i);
            %>
                            {
                            id: '<%= adopter.get("id")%>',
                                    name: '<%= adopter.get("name")%>',
                                    email: '<%= adopter.get("email")%>',
                                    date: '<%= adopter.get("date")%>',
                                    status: '<%= adopter.get("status")%>',
                                    statusColor: '<%= adopter.get("statusColor")%>',
                                    statusText: '<%= adopter.get("statusText")%>'
                            }<%= i < recentAdopters.size() - 1 ? "," : ""%>
            <% } %>
                            ];
                            // Sample Data for Shelter Registrations - USING REAL DATA FROM JSP
                            const shelterRegistrations = [
            <% for (int i = 0; i < recentShelters.size(); i++) {
                    Map<String, Object> shelter = recentShelters.get(i);
            %>
                            {
                            id: '<%= shelter.get("id")%>',
                                    name: '<%= shelter.get("name")%>',
                                    email: '<%= shelter.get("email")%>',
                                    date: '<%= shelter.get("date")%>',
                                    status: '<%= shelter.get("status")%>',
                                    statusColor: '<%= shelter.get("statusColor")%>',
                                    statusText: '<%= shelter.get("statusText")%>'
                            }<%= i < recentShelters.size() - 1 ? "," : ""%>
            <% }%>
                            ];
                            // Pagination Configuration
                            const itemsPerPage = 5;
                            let currentAdopterPage = 1;
                            let currentShelterPage = 1;
                            // Function to render adopter table
                            function renderAdopterTable(page) {
                            const startIndex = (page - 1) * itemsPerPage;
                            const endIndex = startIndex + itemsPerPage;
                            const pageData = adopterRegistrations.slice(startIndex, endIndex);
                            const totalPages = Math.ceil(adopterRegistrations.length / itemsPerPage);
                            // Update table body
                            const tableBody = document.getElementById('adopterTableBody');
                            tableBody.innerHTML = '';
                            pageData.forEach(adopter => {
                            const row = document.createElement('tr');
                            row.className = 'border-b border-[#E5E5E5] hover:bg-[#F6F3E7]';
                            row.innerHTML =
                                    row.innerHTML =
                                    '<td class="py-3 px-4">' +
                                    '<div>' +
                                    '<span class="font-medium block" style="color: #2B2B2B;">' + adopter.name + '</span>' +
                                    '<span class="text-xs text-gray-500">' + adopter.email + '</span>' +
                                    '</div>' +
                                    '</td>' +
                                    '<td class="py-3 px-4">' +
                                    '<span class="text-gray-500 text-sm">' + adopter.date + '</span>' +
                                    '</td>' +
                                    '<td class="py-3 px-4">' +
                                    '<span class="px-2 py-1 text-xs rounded-full" style="background-color: ' + adopter.statusColor + '; color: ' + adopter.statusText + '; border: 1px solid ' + adopter.statusColor + '">' +
                                    adopter.status +
                                    '</span>' +
                                    '</td>';
                            tableBody.appendChild(row);
                            });
                            // Update pagination info
                            document.getElementById('adopterStart').textContent = startIndex + 1;
                            document.getElementById('adopterEnd').textContent = Math.min(endIndex, adopterRegistrations.length);
                            document.getElementById('adopterTotal').textContent = adopterRegistrations.length;
                            // Render pagination buttons
                            renderPagination('adopter', page, totalPages);
                            }

                            // Function to render shelter table
                            function renderShelterTable(page) {
                            const startIndex = (page - 1) * itemsPerPage;
                            const endIndex = startIndex + itemsPerPage;
                            const pageData = shelterRegistrations.slice(startIndex, endIndex);
                            const totalPages = Math.ceil(shelterRegistrations.length / itemsPerPage);
                            // Update table body
                            const tableBody = document.getElementById('shelterTableBody');
                            tableBody.innerHTML = '';
                            pageData.forEach(shelter => {
                            const row = document.createElement('tr');
                            row.className = 'border-b border-[#E5E5E5] hover:bg-[#F6F3E7]';
                            row.innerHTML =
                                    '<td class="py-3 px-4">' +
                                    '<div>' +
                                    '<span class="font-medium block" style="color: #2B2B2B;">' + shelter.name + '</span>' +
                                    '<span class="text-xs text-gray-500">' + shelter.email + '</span>' +
                                    '</div>' +
                                    '</td>' +
                                    '<td class="py-3 px-4">' +
                                    '<span class="text-gray-500 text-sm">' + shelter.date + '</span>' +
                                    '</td>' +
                                    '<td class="py-3 px-4">' +
                                    '<span class="px-2 py-1 text-xs rounded-full" style="background-color: ' + shelter.statusColor + '; color: ' + shelter.statusText + '; border: 1px solid ' + shelter.statusColor + '">' +
                                    shelter.status +
                                    '</span>' +
                                    '</td>';
                            tableBody.appendChild(row);
                            });
                            // Update pagination info
                            document.getElementById('shelterStart').textContent = startIndex + 1;
                            document.getElementById('shelterEnd').textContent = Math.min(endIndex, shelterRegistrations.length);
                            document.getElementById('shelterTotal').textContent = shelterRegistrations.length;
                            // Render pagination buttons
                            renderPagination('shelter', page, totalPages);
                            }

                            // Function to render pagination buttons
                            function renderPagination(type, currentPage, totalPages) {
                            const paginationContainer = document.getElementById(type + 'Pagination');
                            paginationContainer.innerHTML = '';
                            // Previous button
                            const prevButton = document.createElement('button');
                            prevButton.className = 'pagination-btn';
                            prevButton.innerHTML = '&laquo;';
                            prevButton.disabled = currentPage === 1;
                            prevButton.addEventListener('click', () => {
                            if (type === 'adopter') {
                            currentAdopterPage--;
                            renderAdopterTable(currentAdopterPage);
                            } else {
                            currentShelterPage--;
                            renderShelterTable(currentShelterPage);
                            }
                            });
                            paginationContainer.appendChild(prevButton);
                            // Page buttons
                            const maxVisiblePages = 3;
                            let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
                            let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
                            if (endPage - startPage + 1 < maxVisiblePages) {
                            startPage = Math.max(1, endPage - maxVisiblePages + 1);
                            }

                            for (let i = startPage; i <= endPage; i++) {
                            const pageButton = document.createElement('button');
                            pageButton.className = 'pagination-btn' + (i === currentPage ? ' active' : '');
                            pageButton.textContent = i;
                            pageButton.addEventListener('click', () => {
                            if (type === 'adopter') {
                            currentAdopterPage = i;
                            renderAdopterTable(currentAdopterPage);
                            } else {
                            currentShelterPage = i;
                            renderShelterTable(currentShelterPage);
                            }
                            });
                            paginationContainer.appendChild(pageButton);
                            }

                            // Next button
                            const nextButton = document.createElement('button');
                            nextButton.className = 'pagination-btn';
                            nextButton.innerHTML = '&raquo;';
                            nextButton.disabled = currentPage === totalPages;
                            nextButton.addEventListener('click', () => {
                            if (type === 'adopter') {
                            currentAdopterPage++;
                            renderAdopterTable(currentAdopterPage);
                            } else {
                            currentShelterPage++;
                            renderShelterTable(currentShelterPage);
                            }
                            });
                            paginationContainer.appendChild(nextButton);
                            }

                            // Helper functions for actions
                            function viewAdopter(adopterId) {
                            // Extract numeric ID from "USR-XXXX"
                            const id = adopterId.replace('USR-', '');
                            window.location.href = 'view_profile.jsp?user_id=' + id; // ← BETUL KAN NAMA PAGE
                            }

                            function viewShelter(shelterId) {
                            // Extract numeric ID from "SHT-XXXX"
                            const id = shelterId.replace('SHT-', '');
                            window.location.href = 'view_profile.jsp?user_id=' + id; // ← SAMA MACAM ADOPTER
                            }

                            function reviewShelter(shelterId) {
                            // Extract numeric ID from "SHT-XXXX"
                            const id = shelterId.replace('SHT-', '');
                            window.location.href = 'review_registrations.jsp?shelter_id=' + id;
                            }

                            // Initialize tables
                            document.addEventListener('DOMContentLoaded', function() {
                            renderAdopterTable(currentAdopterPage);
                            renderShelterTable(currentShelterPage);
                            // Auto-refresh data every 2 minutes
                            setInterval(() => {
                            location.reload();
                            }, 120000); // 120000ms = 2 minutes
                            });
        </script>

    </body>
</html>