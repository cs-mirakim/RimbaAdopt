<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>

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
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Approve Registrations - Rimba Adopt Admin</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
            /* Consistent with dashboard styles */
            .registration-card {
                border: 1px solid #E5E5E5;
                border-radius: 0.75rem;
                overflow: hidden;
                box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
            }

            .registration-header {
                background-color: #F6F3E7;
                padding: 1rem 1.5rem;
                border-bottom: 1px solid #E5E5E5;
            }

            .registration-table-container {
                overflow-y: auto;
                max-height: 600px;
            }

            .status-badge {
                padding: 4px 12px;
                border-radius: 9999px;
                font-size: 0.75rem;
                font-weight: 500;
                display: inline-flex;
                align-items: center;
            }

            .status-badge::before {
                content: '';
                display: inline-block;
                width: 8px;
                height: 8px;
                border-radius: 50%;
                margin-right: 6px;
            }

            .status-pending {
                background-color: rgba(196, 154, 108, 0.15);
                color: #B38459;
                border: 1px solid rgba(196, 154, 108, 0.3);
            }

            .status-pending::before {
                background-color: #C49A6C;
            }

            .status-approved {
                background-color: rgba(109, 191, 137, 0.15);
                color: #378A5E;
                border: 1px solid rgba(109, 191, 137, 0.3);
            }

            .status-approved::before {
                background-color: #6DBF89;
            }

            .status-rejected {
                background-color: rgba(184, 74, 74, 0.15);
                color: #B84A4A;
                border: 1px solid rgba(184, 74, 74, 0.3);
            }

            .status-rejected::before {
                background-color: #B84A4A;
            }

            .status-new {
                background-color: rgba(168, 230, 207, 0.15);
                color: #4A9C7A;
                border: 1px solid rgba(168, 230, 207, 0.3);
            }

            .status-new::before {
                background-color: #A8E6CF;
            }

            .tab-button {
                padding: 0.75rem 1.5rem;
                font-weight: 500;
                border-bottom: 3px solid transparent;
                transition: all 0.2s ease;
            }

            .tab-button.active {
                border-bottom-color: #2F5D50;
                color: #2F5D50;
            }

            .tab-button:hover:not(.active) {
                border-bottom-color: rgba(47, 93, 80, 0.3);
                color: #2F5D50;
            }

            .action-btn {
                padding: 0.5rem 1rem;
                border-radius: 0.375rem;
                font-size: 0.875rem;
                font-weight: 500;
                transition: all 0.2s ease;
            }

            .action-btn-approve {
                background-color: #6DBF89;
                color: white;
            }

            .action-btn-approve:hover {
                background-color: #57A677;
            }

            .action-btn-reject {
                background-color: #F6F3E7;
                color: #2B2B2B;
                border: 1px solid #E5E5E5;
            }

            .action-btn-reject:hover {
                background-color: #E8E3D5;
            }

            .action-btn-view {
                background-color: #2F5D50;
                color: white;
            }

            .action-btn-view:hover {
                background-color: #24483E;
            }

            .filter-chip {
                display: inline-flex;
                align-items: center;
                padding: 0.375rem 0.75rem;
                border-radius: 9999px;
                font-size: 0.875rem;
                margin-right: 0.5rem;
                margin-bottom: 0.5rem;
                background-color: #F6F3E7;
                color: #2B2B2B;
                border: 1px solid #E5E5E5;
                cursor: pointer;
                transition: all 0.2s ease;
            }

            .filter-chip.active {
                background-color: #2F5D50;
                color: white;
                border-color: #2F5D50;
            }

            .filter-chip:hover:not(.active) {
                background-color: #E8E3D5;
            }

            .filter-chip .remove {
                margin-left: 0.5rem;
                opacity: 0.7;
            }

            .filter-chip .remove:hover {
                opacity: 1;
            }

            /* Modal styles */
            .modal-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: rgba(0, 0, 0, 0.5);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 50;
                opacity: 0;
                visibility: hidden;
                transition: all 0.3s ease;
            }

            .modal-overlay.active {
                opacity: 1;
                visibility: visible;
            }

            .modal-content {
                background-color: white;
                border-radius: 0.75rem;
                max-width: 600px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
                transform: translateY(20px);
                transition: transform 0.3s ease;
            }

            .modal-overlay.active .modal-content {
                transform: translateY(0);
            }

            .detail-row {
                padding: 0.75rem 0;
                border-bottom: 1px solid #F6F3E7;
                display: flex;
            }

            .detail-label {
                width: 40%;
                font-weight: 500;
                color: #2F5D50;
            }

            .detail-value {
                width: 60%;
                color: #2B2B2B;
            }

            /* Approval reason modal specific styles */
            .approval-reason-textarea {
                width: 100%;
                min-height: 120px;
                padding: 0.75rem;
                border: 1px solid #E5E5E5;
                border-radius: 0.5rem;
                font-family: inherit;
                font-size: 0.875rem;
                resize: vertical;
                transition: border-color 0.2s ease;
            }

            .approval-reason-textarea:focus {
                outline: none;
                border-color: #2F5D50;
                box-shadow: 0 0 0 3px rgba(47, 93, 80, 0.1);
            }

            .reason-preset-btn {
                display: block;
                width: 100%;
                text-align: left;
                padding: 0.5rem 0.75rem;
                margin-bottom: 0.5rem;
                border: 1px solid #E5E5E5;
                border-radius: 0.375rem;
                background-color: #F6F3E7;
                font-size: 0.875rem;
                color: #2B2B2B;
                cursor: pointer;
                transition: all 0.2s ease;
            }

            .reason-preset-btn:hover {
                background-color: #E8E3D5;
                border-color: #C49A6C;
            }

            .approval-reason-preset-btn {
                background-color: rgba(109, 191, 137, 0.1);
                border-color: rgba(109, 191, 137, 0.3);
            }

            .approval-reason-preset-btn:hover {
                background-color: rgba(109, 191, 137, 0.2);
                border-color: #6DBF89;
            }

            .rejection-reason-textarea {
                width: 100%;
                min-height: 120px;
                padding: 0.75rem;
                border: 1px solid #E5E5E5;
                border-radius: 0.5rem;
                font-family: inherit;
                font-size: 0.875rem;
                resize: vertical;
                transition: border-color 0.2s ease;
            }

            .rejection-reason-textarea:focus {
                outline: none;
                border-color: #2F5D50;
                box-shadow: 0 0 0 3px rgba(47, 93, 80, 0.1);
            }

            .rejection-history-item {
                padding: 0.75rem;
                border-bottom: 1px solid #F6F3E7;
                background-color: rgba(184, 74, 74, 0.05);
                border-radius: 0.375rem;
                margin-bottom: 0.5rem;
            }

            .approval-history-item {
                padding: 0.75rem;
                border-bottom: 1px solid #F6F3E7;
                background-color: rgba(109, 191, 137, 0.05);
                border-radius: 0.375rem;
                margin-bottom: 0.5rem;
            }

            .rejection-history-reason {
                font-style: italic;
                color: #B84A4A;
                margin-top: 0.25rem;
                padding-left: 1rem;
                border-left: 2px solid #B84A4A;
            }

            .approval-history-reason {
                font-style: italic;
                color: #378A5E;
                margin-top: 0.25rem;
                padding-left: 1rem;
                border-left: 2px solid #6DBF89;
            }

            /* Pagination */
            .pagination-btn {
                padding: 0.5rem 0.75rem;
                margin: 0 0.125rem;
                border-radius: 0.25rem;
                background-color: #F6F3E7;
                color: #2B2B2B;
                border: 1px solid #E5E5E5;
                cursor: pointer;
                transition: all 0.2s ease;
            }

            .pagination-btn:hover {
                background-color: #E8E3D5;
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

            /* Toast notification */
            .toast {
                position: fixed;
                top: 1rem;
                right: 1rem;
                padding: 1rem 1.5rem;
                border-radius: 0.5rem;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                z-index: 100;
                display: flex;
                align-items: center;
                transform: translateX(400px);
                transition: transform 0.3s ease;
            }

            .toast.show {
                transform: translateX(0);
            }

            .toast-success {
                background-color: #6DBF89;
                color: white;
                border-left: 4px solid #378A5E;
            }

            .toast-error {
                background-color: #B84A4A;
                color: white;
                border-left: 4px solid #8A2B2B;
            }

            /* Approval stats */
            .approval-reasons-chart {
                height: 200px;
                position: relative;
            }

            .reason-box {
                padding: 0.75rem;
                border-radius: 0.5rem;
                margin-bottom: 0.5rem;
                font-size: 0.875rem;
            }

            .approval-reason-box {
                background-color: rgba(109, 191, 137, 0.1);
                border: 1px solid rgba(109, 191, 137, 0.3);
                color: #378A5E;
            }

            .rejection-reason-box {
                background-color: rgba(184, 74, 74, 0.1);
                border: 1px solid rgba(184, 74, 74, 0.3);
                color: #B84A4A;
            }

            /* No data styles */
            .no-data-row {
                padding: 3rem 1rem;
                text-align: center;
            }

            .no-data-icon {
                font-size: 3rem;
                margin-bottom: 1rem;
                color: #C49A6C;
            }

            .no-data-message {
                color: #2B2B2B;
                font-size: 1.125rem;
                margin-bottom: 0.5rem;
            }

            .no-data-submessage {
                color: #6B7280;
                font-size: 0.875rem;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Main Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Page Header -->
                <div class="mb-8 pb-4 border-b border-[#E5E5E5]">
                    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div>
                            <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Approve Registrations</h1>
                            <p class="mt-2 text-lg" style="color: #2B2B2B;">
                                Review and approve or reject pending user and shelter registrations.
                            </p>
                        </div>
                        <div class="flex items-center space-x-2">
                            <a href="dashboard_admin.jsp" class="action-btn action-btn-view">
                                <svg class="w-4 h-4 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7 7-7m8 14l-7-7 7-7"/>
                                </svg>
                                Back to Dashboard
                            </a>
                        </div>
                    </div>
                </div>

                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                    <!-- Pending Approvals -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm font-medium" style="color: #C49A6C;">Pending Approvals</p>
                                <p class="text-3xl font-bold mt-1" style="color: #2B2B2B;" id="pending-count">0</p>
                            </div>
                            <div class="w-12 h-12 rounded-full flex items-center justify-center" style="background-color: rgba(196, 154, 108, 0.2);">
                                <svg class="w-6 h-6" style="color: #C49A6C;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                        </div>
                        <p class="text-xs text-gray-500 mt-2" id="pending-detail">0 shelters awaiting review</p>
                    </div>

                    <!-- Approved Today -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm font-medium" style="color: #6DBF89;">Approved Today</p>
                                <p class="text-3xl font-bold mt-1" style="color: #2B2B2B;" id="approved-today">0</p>
                            </div>
                            <div class="w-12 h-12 rounded-full flex items-center justify-center" style="background-color: rgba(109, 191, 137, 0.2);">
                                <svg class="w-6 h-6" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                        </div>
                        <p class="text-xs text-gray-500 mt-2" id="approved-detail">0 shelters approved today</p>
                    </div>

                    <!-- Rejected Today -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm font-medium" style="color: #B84A4A;">Rejected Today</p>
                                <p class="text-3xl font-bold mt-1" style="color: #2B2B2B;" id="rejected-today">0</p>
                            </div>
                            <div class="w-12 h-12 rounded-full flex items-center justify-center" style="background-color: rgba(184, 74, 74, 0.2);">
                                <svg class="w-6 h-6" style="color: #B84A4A;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                        </div>
                        <p class="text-xs text-gray-500 mt-2" id="rejected-detail">0 shelters rejected today</p>
                    </div>

                    <!-- Rejection Rate -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm font-medium" style="color: #2F5D50;">Rejection Rate</p>
                                <p class="text-3xl font-bold mt-1" style="color: #2B2B2B;" id="rejection-rate">0%</p>
                            </div>
                            <div class="w-12 h-12 rounded-full flex items-center justify-center" style="background-color: rgba(47, 93, 80, 0.2);">
                                <svg class="w-6 h-6" style="color: #2F5D50;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                                </svg>
                            </div>
                        </div>
                        <p class="text-xs text-gray-500 mt-2">Of total registrations this month</p>
                    </div>
                </div>

                <!-- Tabs and Filters -->
                <div class="mb-6">
                    <!-- Tabs -->
                    <div class="flex border-b border-[#E5E5E5] mb-4">
                        <button class="tab-button active" data-tab="all">All Registrations</button>
                        <button class="tab-button" data-tab="shelters">Shelters</button>
                        <button class="tab-button" data-tab="adopters">Adopters</button>
                        <button class="tab-button" data-tab="rejected">Rejected</button>
                    </div>

                    <!-- Filters -->
                    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div>
                            <span class="text-sm font-medium mr-2" style="color: #2B2B2B;">Filter by:</span>
                            <div id="filter-chips" class="inline">
                                <!-- Filter chips will be added here by JavaScript -->
                            </div>
                        </div>
                        <div class="flex items-center space-x-2">
                            <select id="status-filter" class="p-2 border border-[#E5E5E5] rounded-lg bg-white text-sm focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent">
                                <option value="all">All Status</option>
                                <option value="pending">Pending</option>
                                <option value="new">New</option>
                                <option value="approved">Approved</option>
                                <option value="rejected">Rejected</option>
                            </select>
                            <input type="date" id="date-filter" class="p-2 border border-[#E5E5E5] rounded-lg bg-white text-sm focus:outline-none focus:ring-2 focus:ring-[#2F5D50] focus:border-transparent">
                            <button id="clear-filters" class="action-btn action-btn-reject">Clear Filters</button>
                        </div>
                    </div>
                </div>

                <!-- Registrations Table -->
                <div class="registration-card">
                    <div class="registration-header">
                        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                            <div class="flex items-center gap-3">
                                <div class="w-10 h-10 rounded-full flex items-center justify-center" style="background-color: #2F5D50;">
                                    <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                                    </svg>
                                </div>
                                <div>
                                    <h3 class="font-semibold text-lg" style="color: #2B2B2B;">Registrations for Review</h3>
                                    <p class="text-sm text-gray-500">Click on any registration to view details and take action</p>
                                </div>
                            </div>
                            <div class="text-sm" style="color: #2B2B2B;">
                                <span id="total-count">0</span> registrations found
                            </div>
                        </div>
                    </div>

                    <div class="registration-table-container">
                        <table class="w-full">
                            <thead class="sticky top-0 z-10" style="background-color: #F6F3E7;">
                                <tr class="border-b border-[#E5E5E5]">
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">ID</th>
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Name / Organization</th>
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Type</th>
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Submitted</th>
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Status</th>
                                    <th class="text-left py-3 px-4 text-sm font-medium" style="color: #2B2B2B;">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="registrationsTableBody">
                                <!-- Registration rows will be inserted here by JavaScript -->
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination -->
                    <div class="flex justify-between items-center p-4 border-t border-[#E5E5E5]">
                        <div class="text-sm" style="color: #2B2B2B;">
                            Showing <span id="start-index">0</span> to <span id="end-index">0</span> of <span id="total-entries">0</span> entries
                        </div>
                        <div class="flex items-center space-x-1" id="pagination">
                            <!-- Pagination buttons will be inserted here by JavaScript -->
                        </div>
                    </div>
                </div>

                <!-- Quick Actions Section -->
                <div class="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
                    <!-- Bulk Actions (1/3 width) -->
                    <div class="md:col-span-1 border border-[#E5E5E5] rounded-xl p-6 shadow-sm">
                        <h3 class="text-lg font-semibold mb-4" style="color: #2B2B2B;">Bulk Actions</h3>
                        <div class="space-y-3">
                            <button id="bulk-approve" class="w-full action-btn action-btn-approve flex items-center justify-center">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                Approve Selected (0)
                            </button>
                            <button id="bulk-reject" class="w-full action-btn action-btn-reject flex items-center justify-center">
                                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                </svg>
                                Reject Selected (0)
                            </button>
                            <div class="text-xs text-gray-500 pt-2">
                                <input type="checkbox" id="select-all" class="mr-2">
                                <label for="select-all">Select all entries on this page</label>
                            </div>
                        </div>
                    </div>

                    <!-- Common Approval Reasons (2/3 width) -->
                    <div class="md:col-span-2 border border-[#E5E5E5] rounded-xl p-6 shadow-sm" style="background-color: rgba(109, 191, 137, 0.05);">
                        <h3 class="text-lg font-semibold mb-4" style="color: #2B2B2B;">Common Approval Reasons</h3>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm" style="color: #2B2B2B;">
                            <div class="flex items-start">
                                <svg class="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Complete documentation meets all requirements</span>
                            </div>
                            <div class="flex items-start">
                                <svg class="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Valid and up-to-date license/certification</span>
                            </div>
                            <div class="flex items-start">
                                <svg class="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Adequate facilities and capacity for animal care</span>
                            </div>
                            <div class="flex items-start">
                                <svg class="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Verifiable contact information and address</span>
                            </div>
                            <div class="flex items-start md:col-span-2">
                                <svg class="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" style="color: #6DBF89;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span>Meets all animal welfare standards</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </main>

    <!-- Footer container -->
    <jsp:include page="includes/footer.jsp" />

    <!-- Registration Details Modal -->
    <div id="registrationModal" class="modal-overlay">
        <div class="modal-content">
            <div class="p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold" style="color: #2B2B2B;">Registration Details</h3>
                    <button id="closeModal" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                <div id="modalContent">
                    <!-- Modal content will be inserted here by JavaScript -->
                </div>

                <div class="flex justify-end space-x-3 mt-8 pt-6 border-t border-[#E5E5E5]">
                    <button id="modalRejectBtn" class="action-btn action-btn-reject">Reject</button>
                    <button id="modalApproveBtn" class="action-btn action-btn-approve">Approve</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Approval Reason Modal -->
    <div id="approvalModal" class="modal-overlay">
        <div class="modal-content">
            <div class="p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold" style="color: #2B2B2B;">Approve Registration</h3>
                    <button id="closeApprovalModal" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                <div class="mb-4">
                    <p class="text-gray-700 mb-2" id="approvalTargetName"></p>
                    <p class="text-sm text-gray-500">Please provide a reason for approving this registration. This reason will be recorded in the system for future reference.</p>
                </div>

                <div class="mb-6">
                    <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Approval Reason (Optional but recommended)</label>
                    <textarea id="approvalReason" class="approval-reason-textarea" placeholder="Enter the reason for approval (e.g., complete documentation, meets requirements)..."></textarea>
                </div>

                <div class="mb-6">
                    <p class="text-sm font-medium mb-2" style="color: #2B2B2B;">Common Reasons (Click to use)</p>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-reason="Complete documentation meets all requirements">
                        Complete documentation meets all requirements
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-reason="Valid and up-to-date license/certification">
                        Valid and up-to-date license/certification
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-reason="Adequate facilities and capacity for animal care">
                        Adequate facilities and capacity for animal care
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-reason="Verifiable contact information and address">
                        Verifiable contact information and address
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-reason="Meets all animal welfare standards and requirements">
                        Meets all animal welfare standards and requirements
                    </button>
                </div>

                <div class="flex justify-end space-x-3 mt-8 pt-6 border-t border-[#E5E5E5]">
                    <button id="cancelApprovalBtn" class="action-btn action-btn-reject">Cancel</button>
                    <button id="confirmApprovalBtn" class="action-btn action-btn-approve">
                        Confirm Approval
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bulk Approval Reason Modal -->
    <div id="bulkApprovalModal" class="modal-overlay">
        <div class="modal-content">
            <div class="p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold" style="color: #2B2B2B;">Approve Multiple Registrations</h3>
                    <button id="closeBulkApprovalModal" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                <div class="mb-4">
                    <p class="text-gray-700 mb-2">You are about to approve <span id="bulkApprovalCount">0</span> registration(s).</p>
                    <p class="text-sm text-gray-500">Please provide a reason for approving these registrations. This reason will be applied to all selected registrations.</p>
                </div>

                <div class="mb-6">
                    <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Approval Reason (Optional but recommended)</label>
                    <textarea id="bulkApprovalReason" class="approval-reason-textarea" placeholder="Enter the reason for approval..."></textarea>
                </div>

                <div class="mb-6">
                    <p class="text-sm font-medium mb-2" style="color: #2B2B2B;">Common Reasons (Click to use)</p>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-bulk-reason="Complete documentation meets all requirements">
                        Complete documentation meets all requirements
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-bulk-reason="Valid and up-to-date license/certification">
                        Valid and up-to-date license/certification
                    </button>
                    <button class="reason-preset-btn approval-reason-preset-btn" data-bulk-reason="Meets all minimum requirements for registration">
                        Meets all minimum requirements for registration
                    </button>
                </div>

                <div class="flex justify-end space-x-3 mt-8 pt-6 border-t border-[#E5E5E5]">
                    <button id="cancelBulkApprovalBtn" class="action-btn action-btn-reject">Cancel</button>
                    <button id="confirmBulkApprovalBtn" class="action-btn action-btn-approve">
                        Approve All Selected
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Rejection Reason Modal -->
    <div id="rejectionModal" class="modal-overlay">
        <div class="modal-content">
            <div class="p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold" style="color: #2B2B2B;">Reject Registration</h3>
                    <button id="closeRejectionModal" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                <div class="mb-4">
                    <p class="text-gray-700 mb-2" id="rejectionTargetName"></p>
                    <p class="text-sm text-gray-500">Please provide a reason for rejecting this registration. This reason will be visible to the user and recorded in the system.</p>
                </div>

                <div class="mb-6">
                    <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Rejection Reason</label>
                    <textarea id="rejectionReason" class="rejection-reason-textarea" placeholder="Enter the reason for rejection..."></textarea>
                </div>

                <div class="mb-6">
                    <p class="text-sm font-medium mb-2" style="color: #2B2B2B;">Common Reasons (Click to use)</p>
                    <button class="reason-preset-btn" data-reason="Incomplete documentation or missing required files">
                        Incomplete documentation or missing required files
                    </button>
                    <button class="reason-preset-btn" data-reason="Invalid or expired license/certification">
                        Invalid or expired license/certification
                    </button>
                    <button class="reason-preset-btn" data-reason="Insufficient facilities or capacity for animal care">
                        Insufficient facilities or capacity for animal care
                    </button>
                    <button class="reason-preset-btn" data-reason="Unverifiable contact information or address">
                        Unverifiable contact information or address
                    </button>
                    <button class="reason-preset-btn" data-reason="Duplicate registration or existing account">
                        Duplicate registration or existing account
                    </button>
                    <button class="reason-preset-btn" data-reason="Does not meet minimum requirements for registration">
                        Does not meet minimum requirements for registration
                    </button>
                </div>

                <div class="flex justify-end space-x-3 mt-8 pt-6 border-t border-[#E5E5E5]">
                    <button id="cancelRejectionBtn" class="action-btn action-btn-reject">Cancel</button>
                    <button id="confirmRejectionBtn" class="action-btn action-btn-reject" style="background-color: #B84A4A; color: white;">
                        Confirm Rejection
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bulk Rejection Reason Modal -->
    <div id="bulkRejectionModal" class="modal-overlay">
        <div class="modal-content">
            <div class="p-6">
                <div class="flex justify-between items-center mb-6">
                    <h3 class="text-xl font-bold" style="color: #2B2B2B;">Reject Multiple Registrations</h3>
                    <button id="closeBulkRejectionModal" class="text-gray-500 hover:text-gray-700">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                    </button>
                </div>

                <div class="mb-4">
                    <p class="text-gray-700 mb-2">You are about to reject <span id="bulkRejectionCount">0</span> registration(s).</p>
                    <p class="text-sm text-gray-500">Please provide a reason for rejecting these registrations. This reason will be applied to all selected registrations.</p>
                </div>

                <div class="mb-6">
                    <label class="block text-sm font-medium mb-2" style="color: #2B2B2B;">Rejection Reason</label>
                    <textarea id="bulkRejectionReason" class="rejection-reason-textarea" placeholder="Enter the reason for rejection..."></textarea>
                </div>

                <div class="mb-6">
                    <p class="text-sm font-medium mb-2" style="color: #2B2B2B;">Common Reasons (Click to use)</p>
                    <button class="reason-preset-btn" data-bulk-reason="Incomplete documentation or missing required files">
                        Incomplete documentation or missing required files
                    </button>
                    <button class="reason-preset-btn" data-bulk-reason="Invalid or expired license/certification">
                        Invalid or expired license/certification
                    </button>
                    <button class="reason-preset-btn" data-bulk-reason="Does not meet minimum requirements for registration">
                        Does not meet minimum requirements for registration
                    </button>
                </div>

                <div class="flex justify-end space-x-3 mt-8 pt-6 border-t border-[#E5E5E5]">
                    <button id="cancelBulkRejectionBtn" class="action-btn action-btn-reject">Cancel</button>
                    <button id="confirmBulkRejectionBtn" class="action-btn action-btn-reject" style="background-color: #B84A4A; color: white;">
                        Reject All Selected
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast Notification -->
    <div id="toast" class="toast">
        <div class="flex items-center">
            <svg id="toast-icon" class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
            <span id="toast-message"></span>
        </div>
    </div>

    <!-- Sidebar container -->
    <jsp:include page="includes/sidebar.jsp" />

    <!-- Load sidebar.js -->
    <script src="includes/sidebar.js"></script>

    <script>
        // State variables
        let currentPage = 1;
        const itemsPerPage = 10;
        let currentFilter = 'all'; // 'all', 'shelters', 'adopters', 'rejected'
        let currentStatusFilter = 'all';
        let currentDateFilter = '';
        let selectedRegistrations = new Set();
        let currentRegistrationId = null;
        let pendingApprovalIds = []; // For bulk approval
        let pendingRejectionIds = []; // For bulk rejection
        let allRegistrations = [];

        // DOM Elements
        const tableBody = document.getElementById('registrationsTableBody');
        const paginationContainer = document.getElementById('pagination');
        const filterChipsContainer = document.getElementById('filter-chips');
        const statusFilter = document.getElementById('status-filter');
        const dateFilter = document.getElementById('date-filter');
        const clearFiltersBtn = document.getElementById('clear-filters');
        const tabButtons = document.querySelectorAll('.tab-button');
        const selectAllCheckbox = document.getElementById('select-all');
        const bulkApproveBtn = document.getElementById('bulk-approve');
        const bulkRejectBtn = document.getElementById('bulk-reject');
        const registrationModal = document.getElementById('registrationModal');
        const closeModalBtn = document.getElementById('closeModal');
        const modalContent = document.getElementById('modalContent');
        const modalApproveBtn = document.getElementById('modalApproveBtn');
        const modalRejectBtn = document.getElementById('modalRejectBtn');
        const approvalModal = document.getElementById('approvalModal');
        const closeApprovalModalBtn = document.getElementById('closeApprovalModal');
        const cancelApprovalBtn = document.getElementById('cancelApprovalBtn');
        const confirmApprovalBtn = document.getElementById('confirmApprovalBtn');
        const approvalReasonTextarea = document.getElementById('approvalReason');
        const approvalTargetName = document.getElementById('approvalTargetName');
        const bulkApprovalModal = document.getElementById('bulkApprovalModal');
        const closeBulkApprovalModalBtn = document.getElementById('closeBulkApprovalModal');
        const cancelBulkApprovalBtn = document.getElementById('cancelBulkApprovalBtn');
        const confirmBulkApprovalBtn = document.getElementById('confirmBulkApprovalBtn');
        const bulkApprovalReasonTextarea = document.getElementById('bulkApprovalReason');
        const bulkApprovalCount = document.getElementById('bulkApprovalCount');
        const rejectionModal = document.getElementById('rejectionModal');
        const closeRejectionModalBtn = document.getElementById('closeRejectionModal');
        const cancelRejectionBtn = document.getElementById('cancelRejectionBtn');
        const confirmRejectionBtn = document.getElementById('confirmRejectionBtn');
        const rejectionReasonTextarea = document.getElementById('rejectionReason');
        const rejectionTargetName = document.getElementById('rejectionTargetName');
        const bulkRejectionModal = document.getElementById('bulkRejectionModal');
        const closeBulkRejectionModalBtn = document.getElementById('closeBulkRejectionModal');
        const cancelBulkRejectionBtn = document.getElementById('cancelBulkRejectionBtn');
        const confirmBulkRejectionBtn = document.getElementById('confirmBulkRejectionBtn');
        const bulkRejectionReasonTextarea = document.getElementById('bulkRejectionReason');
        const bulkRejectionCount = document.getElementById('bulkRejectionCount');
        const toast = document.getElementById('toast');
        const toastMessage = document.getElementById('toast-message');
        const toastIcon = document.getElementById('toast-icon');
        const totalCountElement = document.getElementById('total-count');
        const startIndexElement = document.getElementById('start-index');
        const endIndexElement = document.getElementById('end-index');
        const totalEntriesElement = document.getElementById('total-entries');

        // Load data from server
        async function loadData() {
            try {
                const response = await fetch('RegistrationServlet?action=getRegistrations');
                if (!response.ok) {
                    throw new Error('Failed to load data');
                }
                allRegistrations = await response.json();
                renderTable();
                loadStatistics();
            } catch (error) {
                console.error('Error loading data:', error);
                showToast('Failed to load registrations', 'error');
                // Show "No data found" message
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="6" class="no-data-row">
                            <div class="no-data-icon">📭</div>
                            <div class="no-data-message">No registrations found</div>
                            <div class="no-data-submessage">Unable to load registration data</div>
                        </td>
                    </tr>
                `;
            }
        }

        // Load statistics
        async function loadStatistics() {
            try {
                const response = await fetch('RegistrationServlet?action=getStatistics');
                if (!response.ok) {
                    throw new Error('Failed to load statistics');
                }
                const stats = await response.json();

                // Update statistics cards
                document.getElementById('pending-count').textContent = stats.pendingCount || 0;
                document.getElementById('pending-detail').textContent =
                        (stats.pendingCount || 0) + ' shelters awaiting review';

                document.getElementById('approved-today').textContent = stats.approvedToday || 0;
                document.getElementById('approved-detail').textContent =
                        (stats.approvedToday || 0) + ' shelters approved today';

                document.getElementById('rejected-today').textContent = stats.rejectedToday || 0;
                document.getElementById('rejected-detail').textContent =
                        (stats.rejectedToday || 0) + ' shelters rejected today';

                document.getElementById('rejection-rate').textContent = stats.rejectionRate + '%';

            } catch (error) {
                console.error('Error loading statistics:', error);
            }
        }

        // Initialize the page
        function init() {
            // Show "No data found" initially
            tableBody.innerHTML = `
                <tr>
                    <td colspan="6" class="no-data-row">
                        <div class="no-data-icon">📭</div>
                        <div class="no-data-message">No registrations found</div>
                        <div class="no-data-submessage">Loading registration data...</div>
                    </td>
                </tr>
            `;

            loadData();
            setupEventListeners();
            updateBulkActionButtons();
        }

        // Set up event listeners
        function setupEventListeners() {
            // Tab buttons
            tabButtons.forEach(button => {
                button.addEventListener('click', () => {
                    tabButtons.forEach(btn => btn.classList.remove('active'));
                    button.classList.add('active');
                    currentFilter = button.getAttribute('data-tab');
                    currentPage = 1;
                    renderTable();
                    updateFilterChips();
                });
            });

            // Status filter
            statusFilter.addEventListener('change', () => {
                currentStatusFilter = statusFilter.value;
                currentPage = 1;
                renderTable();
                updateFilterChips();
            });

            // Date filter
            dateFilter.addEventListener('change', () => {
                currentDateFilter = dateFilter.value;
                currentPage = 1;
                renderTable();
                updateFilterChips();
            });

            // Clear filters
            clearFiltersBtn.addEventListener('click', () => {
                currentFilter = 'all';
                currentStatusFilter = 'all';
                currentDateFilter = '';

                // Reset UI
                tabButtons.forEach(btn => {
                    btn.classList.remove('active');
                    if (btn.getAttribute('data-tab') === 'all') {
                        btn.classList.add('active');
                    }
                });

                statusFilter.value = 'all';
                dateFilter.value = '';

                currentPage = 1;
                renderTable();
                updateFilterChips();
            });

            // Select all checkbox
            selectAllCheckbox.addEventListener('change', () => {
                const currentPageData = getFilteredData();
                const startIndex = (currentPage - 1) * itemsPerPage;
                const endIndex = startIndex + itemsPerPage;
                const pageData = currentPageData.slice(startIndex, endIndex);

                if (selectAllCheckbox.checked) {
                    pageData.forEach(item => selectedRegistrations.add(item.id));
                } else {
                    pageData.forEach(item => selectedRegistrations.delete(item.id));
                }

                updateRowSelections();
                updateBulkActionButtons();
            });

            // Bulk actions
            bulkApproveBtn.addEventListener('click', () => {
                if (selectedRegistrations.size === 0) {
                    showToast('Please select at least one registration to approve', 'error');
                    return;
                }

                // Filter only pending shelters
                const pendingShelters = Array.from(selectedRegistrations).filter(id => {
                    const reg = allRegistrations.find(r => r.id === id);
                    return reg && reg.type === 'Shelter' && reg.status === 'pending';
                });

                if (pendingShelters.length === 0) {
                    showToast('Only pending shelters can be approved', 'error');
                    return;
                }

                // Show bulk approval modal
                pendingApprovalIds = pendingShelters;
                bulkApprovalCount.textContent = pendingApprovalIds.length;
                bulkApprovalReasonTextarea.value = '';
                bulkApprovalModal.classList.add('active');
            });

            bulkRejectBtn.addEventListener('click', () => {
                if (selectedRegistrations.size === 0) {
                    showToast('Please select at least one registration to reject', 'error');
                    return;
                }

                // Filter only pending shelters
                const pendingShelters = Array.from(selectedRegistrations).filter(id => {
                    const reg = allRegistrations.find(r => r.id === id);
                    return reg && reg.type === 'Shelter' && reg.status === 'pending';
                });

                if (pendingShelters.length === 0) {
                    showToast('Only pending shelters can be rejected', 'error');
                    return;
                }

                // Show bulk rejection modal
                pendingRejectionIds = pendingShelters;
                bulkRejectionCount.textContent = pendingRejectionIds.length;
                bulkRejectionReasonTextarea.value = '';
                bulkRejectionModal.classList.add('active');
            });

            // Registration modal close button
            closeModalBtn.addEventListener('click', () => {
                registrationModal.classList.remove('active');
            });

            // Registration modal approve button
            modalApproveBtn.addEventListener('click', () => {
                if (currentRegistrationId) {
                    const registration = allRegistrations.find(r => r.id === currentRegistrationId);
                    if (registration && registration.type === 'Shelter' && registration.status === 'pending') {
                        // Show approval reason modal
                        approvalTargetName.textContent = 'Approve ' + registration.name + ' (' + registration.id + ')?';
                        approvalReasonTextarea.value = '';
                        approvalModal.classList.add('active');
                    } else {
                        showToast('Only pending shelters can be approved', 'error');
                    }
                }
            });

            // Registration modal reject button
            modalRejectBtn.addEventListener('click', () => {
                if (currentRegistrationId) {
                    const registration = allRegistrations.find(r => r.id === currentRegistrationId);
                    if (registration && registration.type === 'Shelter' && registration.status === 'pending') {
                        // Show rejection reason modal
                        rejectionTargetName.textContent = 'Reject ' + registration.name + ' (' + registration.id + ')?';
                        rejectionReasonTextarea.value = '';
                        rejectionModal.classList.add('active');
                    } else {
                        showToast('Only pending shelters can be rejected', 'error');
                    }
                }
            });

            // Approval modal close button
            closeApprovalModalBtn.addEventListener('click', () => {
                approvalModal.classList.remove('active');
            });

            // Approval modal cancel button
            cancelApprovalBtn.addEventListener('click', () => {
                approvalModal.classList.remove('active');
            });

            // Approval modal confirm button
            confirmApprovalBtn.addEventListener('click', async () => {
                const reason = approvalReasonTextarea.value.trim();
                const registration = allRegistrations.find(r => r.id === currentRegistrationId);

                if (!registration || registration.type !== 'Shelter') {
                    showToast('Invalid registration', 'error');
                    return;
                }

                try {
                    const formData = new FormData();
                    formData.append('action', 'approve');
                    formData.append('shelterId', registration.userId);
                    formData.append('reason', reason);

                    const response = await fetch('RegistrationServlet', {
                        method: 'POST',
                        body: new URLSearchParams(formData)
                    });

                    const result = await response.json();

                    if (result.success) {
                        // Update local data
                        registration.status = 'approved';
                        registration.approvalReason = reason;
                        registration.rejectionReason = '';

                        renderTable();
                        approvalModal.classList.remove('active');
                        registrationModal.classList.remove('active');
                        loadStatistics(); // Refresh statistics
                        showToast('Registration ' + currentRegistrationId + ' approved', 'success');
                    } else {
                        showToast('Failed to approve registration', 'error');
                    }
                } catch (error) {
                    console.error('Error approving registration:', error);
                    showToast('Failed to approve registration', 'error');
                }
            });

            // Bulk approval modal close button
            closeBulkApprovalModalBtn.addEventListener('click', () => {
                bulkApprovalModal.classList.remove('active');
            });

            // Bulk approval modal cancel button
            cancelBulkApprovalBtn.addEventListener('click', () => {
                bulkApprovalModal.classList.remove('active');
            });

            // Bulk approval modal confirm button
            confirmBulkApprovalBtn.addEventListener('click', async () => {
                const reason = bulkApprovalReasonTextarea.value.trim();

                try {
                    const formData = new FormData();
                    formData.append('action', 'bulkApprove');
                    formData.append('reason', reason);
                    pendingApprovalIds.forEach(id => {
                        const reg = allRegistrations.find(r => r.id === id);
                        if (reg) {
                            formData.append('shelterIds[]', reg.userId);
                        }
                    });

                    const response = await fetch('RegistrationServlet', {
                        method: 'POST',
                        body: new URLSearchParams(formData)
                    });

                    const result = await response.json();

                    if (result.success) {
                        // Update local data
                        pendingApprovalIds.forEach(id => {
                            const reg = allRegistrations.find(r => r.id === id);
                            if (reg) {
                                reg.status = 'approved';
                                reg.approvalReason = reason;
                                reg.rejectionReason = '';
                            }
                        });

                        selectedRegistrations.clear();
                        pendingApprovalIds = [];
                        selectAllCheckbox.checked = false;
                        renderTable();
                        bulkApprovalModal.classList.remove('active');
                        updateBulkActionButtons();
                        loadStatistics(); // Refresh statistics
                        showToast(result.count + ' registration(s) approved', 'success');
                    } else {
                        showToast('Failed to approve registrations', 'error');
                    }
                } catch (error) {
                    console.error('Error bulk approving:', error);
                    showToast('Failed to approve registrations', 'error');
                }
            });

            // Rejection modal close button
            closeRejectionModalBtn.addEventListener('click', () => {
                rejectionModal.classList.remove('active');
            });

            // Rejection modal cancel button
            cancelRejectionBtn.addEventListener('click', () => {
                rejectionModal.classList.remove('active');
            });

            // Rejection modal confirm button
            confirmRejectionBtn.addEventListener('click', async () => {
                const reason = rejectionReasonTextarea.value.trim();
                if (!reason) {
                    showToast('Please provide a reason for rejection', 'error');
                    return;
                }

                const registration = allRegistrations.find(r => r.id === currentRegistrationId);

                if (!registration || registration.type !== 'Shelter') {
                    showToast('Invalid registration', 'error');
                    return;
                }

                try {
                    const formData = new FormData();
                    formData.append('action', 'reject');
                    formData.append('shelterId', registration.userId);
                    formData.append('reason', reason);

                    const response = await fetch('RegistrationServlet', {
                        method: 'POST',
                        body: new URLSearchParams(formData)
                    });

                    const result = await response.json();

                    if (result.success) {
                        // Update local data
                        registration.status = 'rejected';
                        registration.rejectionReason = reason;
                        registration.approvalReason = '';

                        renderTable();
                        rejectionModal.classList.remove('active');
                        registrationModal.classList.remove('active');
                        loadStatistics(); // Refresh statistics
                        showToast('Registration ' + currentRegistrationId + ' rejected', 'success');
                    } else {
                        showToast(result.error || 'Failed to reject registration', 'error');
                    }
                } catch (error) {
                    console.error('Error rejecting registration:', error);
                    showToast('Failed to reject registration', 'error');
                }
            });

            // Bulk rejection modal close button
            closeBulkRejectionModalBtn.addEventListener('click', () => {
                bulkRejectionModal.classList.remove('active');
            });

            // Bulk rejection modal cancel button
            cancelBulkRejectionBtn.addEventListener('click', () => {
                bulkRejectionModal.classList.remove('active');
            });

            // Bulk rejection modal confirm button
            confirmBulkRejectionBtn.addEventListener('click', async () => {
                const reason = bulkRejectionReasonTextarea.value.trim();
                if (!reason) {
                    showToast('Please provide a reason for rejection', 'error');
                    return;
                }

                try {
                    const formData = new FormData();
                    formData.append('action', 'bulkReject');
                    formData.append('reason', reason);
                    pendingRejectionIds.forEach(id => {
                        const reg = allRegistrations.find(r => r.id === id);
                        if (reg) {
                            formData.append('shelterIds[]', reg.userId);
                        }
                    });

                    const response = await fetch('RegistrationServlet', {
                        method: 'POST',
                        body: new URLSearchParams(formData)
                    });

                    const result = await response.json();

                    if (result.success) {
                        // Update local data
                        pendingRejectionIds.forEach(id => {
                            const reg = allRegistrations.find(r => r.id === id);
                            if (reg) {
                                reg.status = 'rejected';
                                reg.rejectionReason = reason;
                                reg.approvalReason = '';
                            }
                        });

                        selectedRegistrations.clear();
                        pendingRejectionIds = [];
                        selectAllCheckbox.checked = false;
                        renderTable();
                        bulkRejectionModal.classList.remove('active');
                        updateBulkActionButtons();
                        loadStatistics(); // Refresh statistics
                        showToast(result.count + ' registration(s) rejected', 'success');
                    } else {
                        showToast(result.error || 'Failed to reject registrations', 'error');
                    }
                } catch (error) {
                    console.error('Error bulk rejecting:', error);
                    showToast('Failed to reject registrations', 'error');
                }
            });

            // Reason preset buttons for approval
            document.querySelectorAll('.reason-preset-btn.approval-reason-preset-btn[data-reason]').forEach(button => {
                button.addEventListener('click', () => {
                    approvalReasonTextarea.value = button.getAttribute('data-reason');
                });
            });

            // Reason preset buttons for bulk approval
            document.querySelectorAll('.reason-preset-btn.approval-reason-preset-btn[data-bulk-reason]').forEach(button => {
                button.addEventListener('click', () => {
                    bulkApprovalReasonTextarea.value = button.getAttribute('data-bulk-reason');
                });
            });

            // Reason preset buttons for rejection
            document.querySelectorAll('.reason-preset-btn[data-reason]').forEach(button => {
                button.addEventListener('click', () => {
                    rejectionReasonTextarea.value = button.getAttribute('data-reason');
                });
            });

            // Reason preset buttons for bulk rejection
            document.querySelectorAll('.reason-preset-btn[data-bulk-reason]').forEach(button => {
                button.addEventListener('click', () => {
                    bulkRejectionReasonTextarea.value = button.getAttribute('data-bulk-reason');
                });
            });

            // Close modals when clicking outside
            registrationModal.addEventListener('click', (e) => {
                if (e.target === registrationModal) {
                    registrationModal.classList.remove('active');
                }
            });

            approvalModal.addEventListener('click', (e) => {
                if (e.target === approvalModal) {
                    approvalModal.classList.remove('active');
                }
            });

            bulkApprovalModal.addEventListener('click', (e) => {
                if (e.target === bulkApprovalModal) {
                    bulkApprovalModal.classList.remove('active');
                }
            });

            rejectionModal.addEventListener('click', (e) => {
                if (e.target === rejectionModal) {
                    rejectionModal.classList.remove('active');
                }
            });

            bulkRejectionModal.addEventListener('click', (e) => {
                if (e.target === bulkRejectionModal) {
                    bulkRejectionModal.classList.remove('active');
                }
            });
        }

        // Get filtered data based on current filters
        function getFilteredData() {
            return allRegistrations.filter(item => {
                // Filter by type (all, shelters, adopters, rejected)
                if (currentFilter !== 'all') {
                    if (currentFilter === 'rejected') {
                        if (item.status !== 'rejected')
                            return false;
                    } else if (currentFilter === 'shelters') {
                        if (item.type !== 'Shelter')
                            return false;
                    } else if (currentFilter === 'adopters') {
                        if (item.type !== 'Adopter')
                            return false;
                    }
                }

                // Filter by status
                if (currentStatusFilter !== 'all') {
                    if (currentStatusFilter === 'pending' && item.status !== 'pending') {
                        return false;
                    }
                    if (currentStatusFilter === 'approved' && item.status !== 'approved') {
                        return false;
                    }
                    if (currentStatusFilter === 'rejected' && item.status !== 'rejected') {
                        return false;
                    }
                    if (currentStatusFilter === 'new') {
                        // For new status, show pending shelters and adopters
                        if (item.status !== 'pending') {
                            return false;
                        }
                    }
                }

                // Filter by date
                if (currentDateFilter && item.date !== currentDateFilter) {
                    return false;
                }

                return true;
            });
        }

        // Render the table with current filter and pagination
        function renderTable() {
            const filteredData = getFilteredData();
            const totalPages = Math.ceil(filteredData.length / itemsPerPage);
            const startIndex = (currentPage - 1) * itemsPerPage;
            const endIndex = startIndex + itemsPerPage;
            const pageData = filteredData.slice(startIndex, endIndex);

            // Clear table body
            tableBody.innerHTML = '';

            // Update counts
            totalCountElement.textContent = filteredData.length;
            startIndexElement.textContent = filteredData.length > 0 ? startIndex + 1 : 0;
            endIndexElement.textContent = Math.min(endIndex, filteredData.length);
            totalEntriesElement.textContent = filteredData.length;

            // Render rows - TAMBAH: Langsung papar "No data found" jika tiada data
            if (pageData.length === 0) {
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="6" class="no-data-row">
                            <div class="no-data-icon">📭</div>
                            <div class="no-data-message">No registrations found</div>
                            <div class="no-data-submessage">Try adjusting your filters or check back later</div>
                        </td>
                    </tr>
                `;
            } else {
                pageData.forEach(item => {
                    const row = document.createElement('tr');
                    row.className = 'border-b border-[#E5E5E5] hover:bg-[#F6F3E7] cursor-pointer';
                    row.setAttribute('data-id', item.id);

                    // Status badge class
                    let statusClass = '';
                    if (item.status === 'pending') {
                        statusClass = 'status-pending';
                    } else if (item.status === 'approved') {
                        statusClass = 'status-approved';
                    } else if (item.status === 'rejected') {
                        statusClass = 'status-rejected';
                    }

                    // Show approval/rejection reason in table
                    let reasonBadge = '';
                    if (item.status === 'rejected' && item.rejectionReason) {
                        const shortReason = item.rejectionReason.length > 60 ? item.rejectionReason.substring(0, 60) + '...' : item.rejectionReason;
                        reasonBadge = '<div class="reason-box rejection-reason-box mt-1">' +
                                '<span class="font-medium">Reason:</span> ' + shortReason +
                                '</div>';
                    } else if (item.status === 'approved' && item.approvalReason) {
                        const shortReason = item.approvalReason.length > 60 ? item.approvalReason.substring(0, 60) + '...' : item.approvalReason;
                        reasonBadge = '<div class="reason-box approval-reason-box mt-1">' +
                                '<span class="font-medium">Reason:</span> ' + shortReason +
                                '</div>';
                    }

                    // Determine row HTML with concatenation
                    const isSelected = selectedRegistrations.has(item.id) ? 'checked' : '';
                    const typeClass = item.type === 'Shelter' ? 'bg-[#F5F0EB] text-[#C49A6C]' : 'bg-[#E8F5EE] text-[#57A677]';

                    let actionButtons = '';
                    if (item.type === 'Shelter' && item.status === 'pending') {
                        actionButtons = '<button class="action-btn action-btn-approve quick-approve" data-id="' + item.id + '">Approve</button>' +
                                '<button class="action-btn action-btn-reject quick-reject" data-id="' + item.id + '">Reject</button>';
                    }

                    row.innerHTML = '<td class="py-3 px-4">' +
                            '<div class="flex items-center">' +
                            '<input type="checkbox" class="row-checkbox mr-3" data-id="' + item.id + '" ' + isSelected + '>' +
                            '<span class="font-mono text-sm" style="color: #2B2B2B;">' + item.id + '</span>' +
                            '</div>' +
                            '</td>' +
                            '<td class="py-3 px-4">' +
                            '<div>' +
                            '<span class="font-medium block" style="color: #2B2B2B;">' + item.name + '</span>' +
                            '<span class="text-xs text-gray-500">' + item.email + '</span>' +
                            reasonBadge +
                            '</div>' +
                            '</td>' +
                            '<td class="py-3 px-4">' +
                            '<span class="px-3 py-1 text-xs rounded-full ' + typeClass + '">' + item.type + '</span>' +
                            '</td>' +
                            '<td class="py-3 px-4">' +
                            '<span class="text-gray-500 text-sm">' + item.date + '</span>' +
                            '</td>' +
                            '<td class="py-3 px-4">' +
                            '<span class="status-badge ' + statusClass + '">' + item.status.charAt(0).toUpperCase() + item.status.slice(1) + '</span>' +
                            '</td>' +
                            '<td class="py-3 px-4">' +
                            '<div class="flex space-x-2">' +
                            '<button class="action-btn action-btn-view view-details" data-id="' + item.id + '">View</button>' +
                            actionButtons +
                            '</div>' +
                            '</td>';

                    tableBody.appendChild(row);
                });
            }

            // Add event listeners to row checkboxes
            document.querySelectorAll('.row-checkbox').forEach(checkbox => {
                checkbox.addEventListener('change', (e) => {
                    e.stopPropagation();
                    const id = checkbox.getAttribute('data-id');

                    if (checkbox.checked) {
                        selectedRegistrations.add(id);
                    } else {
                        selectedRegistrations.delete(id);
                        selectAllCheckbox.checked = false;
                    }

                    updateBulkActionButtons();
                });
            });

            // Add event listeners to view buttons
            document.querySelectorAll('.view-details').forEach(button => {
                button.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const id = button.getAttribute('data-id');
                    showRegistrationDetails(id);
                });
            });

            // Add event listeners to quick approve buttons
            document.querySelectorAll('.quick-approve').forEach(button => {
                button.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const id = button.getAttribute('data-id');
                    const registration = allRegistrations.find(r => r.id === id);
                    if (registration) {
                        // Show approval reason modal
                        currentRegistrationId = id;
                        approvalTargetName.textContent = 'Approve ' + registration.name + ' (' + registration.id + ')?';
                        approvalReasonTextarea.value = '';
                        approvalModal.classList.add('active');
                    }
                });
            });

            // Add event listeners to quick reject buttons
            document.querySelectorAll('.quick-reject').forEach(button => {
                button.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const id = button.getAttribute('data-id');
                    const registration = allRegistrations.find(r => r.id === id);
                    if (registration) {
                        // Show rejection reason modal
                        currentRegistrationId = id;
                        rejectionTargetName.textContent = 'Reject ' + registration.name + ' (' + registration.id + ')?';
                        rejectionReasonTextarea.value = '';
                        rejectionModal.classList.add('active');
                    }
                });
            });

            // Add click event to entire row (for viewing details)
            document.querySelectorAll('tr[data-id]').forEach(row => {
                row.addEventListener('click', (e) => {
                    // Don't trigger if clicking on a button or checkbox
                    if (!e.target.closest('button') && !e.target.closest('input[type="checkbox"]')) {
                        const id = row.getAttribute('data-id');
                        showRegistrationDetails(id);
                    }
                });
            });

            // Render pagination
            renderPagination(totalPages);

            // Update select all checkbox state
            updateSelectAllState(pageData);
        }

        // Update select all checkbox state
        function updateSelectAllState(pageData) {
            const allSelected = pageData.length > 0 && pageData.every(item => selectedRegistrations.has(item.id));
            selectAllCheckbox.checked = allSelected;
        }

        // Update row selection visuals
        function updateRowSelections() {
            document.querySelectorAll('.row-checkbox').forEach(checkbox => {
                const id = checkbox.getAttribute('data-id');
                checkbox.checked = selectedRegistrations.has(id);
            });
        }

        // Update bulk action buttons
        function updateBulkActionButtons() {
            const count = selectedRegistrations.size;
            bulkApproveBtn.textContent = 'Approve Selected (' + count + ')';
            bulkRejectBtn.textContent = 'Reject Selected (' + count + ')';
            bulkApproveBtn.disabled = count === 0;
            bulkRejectBtn.disabled = count === 0;
        }

        // Render pagination buttons
        function renderPagination(totalPages) {
            paginationContainer.innerHTML = '';

            // Previous button
            const prevButton = document.createElement('button');
            prevButton.className = 'pagination-btn';
            prevButton.innerHTML = '&laquo;';
            prevButton.disabled = currentPage === 1;
            prevButton.addEventListener('click', () => {
                if (currentPage > 1) {
                    currentPage--;
                    renderTable();
                }
            });
            paginationContainer.appendChild(prevButton);

            // Page buttons
            const maxVisiblePages = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
            let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);

            if (endPage - startPage + 1 < maxVisiblePages) {
                startPage = Math.max(1, endPage - maxVisiblePages + 1);
            }

            for (let i = startPage; i <= endPage; i++) {
                const pageButton = document.createElement('button');
                pageButton.className = 'pagination-btn ' + (i === currentPage ? 'active' : '');
                pageButton.textContent = i;
                pageButton.addEventListener('click', () => {
                    currentPage = i;
                    renderTable();
                });
                paginationContainer.appendChild(pageButton);
            }

            // Next button
            const nextButton = document.createElement('button');
            nextButton.className = 'pagination-btn';
            nextButton.innerHTML = '&raquo;';
            nextButton.disabled = currentPage === totalPages;
            nextButton.addEventListener('click', () => {
                if (currentPage < totalPages) {
                    currentPage++;
                    renderTable();
                }
            });
            paginationContainer.appendChild(nextButton);
        }

        // Update filter chips
        function updateFilterChips() {
            filterChipsContainer.innerHTML = '';

            // Add type filter chip
            if (currentFilter !== 'all') {
                const typeChip = document.createElement('div');
                typeChip.className = 'filter-chip active';
                let filterText = '';
                if (currentFilter === 'shelters')
                    filterText = 'Shelters';
                else if (currentFilter === 'adopters')
                    filterText = 'Adopters';
                else if (currentFilter === 'rejected')
                    filterText = 'Rejected';

                typeChip.innerHTML = filterText +
                        '<span class="remove" data-filter="type">&times;</span>';

                typeChip.querySelector('.remove').addEventListener('click', (e) => {
                    e.stopPropagation();
                    // Reset to "all" tab
                    tabButtons.forEach(btn => {
                        btn.classList.remove('active');
                        if (btn.getAttribute('data-tab') === 'all') {
                            btn.classList.add('active');
                        }
                    });
                    currentFilter = 'all';
                    renderTable();
                    updateFilterChips();
                });
                filterChipsContainer.appendChild(typeChip);
            }

            // Add status filter chip
            if (currentStatusFilter !== 'all') {
                const statusChip = document.createElement('div');
                statusChip.className = 'filter-chip active';
                const statusText = currentStatusFilter.charAt(0).toUpperCase() + currentStatusFilter.slice(1);
                statusChip.innerHTML = statusText +
                        '<span class="remove" data-filter="status">&times;</span>';
                statusChip.querySelector('.remove').addEventListener('click', (e) => {
                    e.stopPropagation();
                    currentStatusFilter = 'all';
                    statusFilter.value = 'all';
                    renderTable();
                    updateFilterChips();
                });
                filterChipsContainer.appendChild(statusChip);
            }

            // Add date filter chip
            if (currentDateFilter) {
                const dateChip = document.createElement('div');
                dateChip.className = 'filter-chip active';
                dateChip.innerHTML = currentDateFilter +
                        '<span class="remove" data-filter="date">&times;</span>';
                dateChip.querySelector('.remove').addEventListener('click', (e) => {
                    e.stopPropagation();
                    currentDateFilter = '';
                    dateFilter.value = '';
                    renderTable();
                    updateFilterChips();
                });
                filterChipsContainer.appendChild(dateChip);
            }
        }

        // Show registration details in modal
        function showRegistrationDetails(id) {
            const registration = allRegistrations.find(r => r.id === id);
            if (!registration)
                return;

            currentRegistrationId = id;

            // Determine status badge
            let statusClass = '';
            if (registration.status === 'pending') {
                statusClass = 'status-pending';
            } else if (registration.status === 'approved') {
                statusClass = 'status-approved';
            } else if (registration.status === 'rejected') {
                statusClass = 'status-rejected';
            }

            // Generate details HTML based on type
            let detailsHTML = '';
            if (registration.type === 'Shelter') {
                detailsHTML = '<div class="mb-6">' +
                        '<div class="flex items-center justify-between mb-4">' +
                        '<div>' +
                        '<h4 class="text-lg font-bold" style="color: #2B2B2B;">' + registration.name + '</h4>' +
                        '<p class="text-gray-500">' + registration.email + '</p>' +
                        '</div>' +
                        '<div>' +
                        '<span class="status-badge ' + statusClass + '">' + registration.status.charAt(0).toUpperCase() + registration.status.slice(1) + '</span>' +
                        '</div>' +
                        '</div>' +
                        '<div class="bg-[#F6F3E7] p-4 rounded-lg mb-4">' +
                        '<h5 class="font-semibold mb-2" style="color: #2F5D50;">Shelter Information</h5>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Contact Person</div>' +
                        '<div class="detail-value">' + (registration.details.contactPerson || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Phone</div>' +
                        '<div class="detail-value">' + (registration.details.phone || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Address</div>' +
                        '<div class="detail-value">' + (registration.details.address || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Description</div>' +
                        '<div class="detail-value">' + (registration.details.description || 'No description provided') + '</div>' +
                        '</div>' +
                        '</div>';

                // Add approval details if approved
                if (registration.status === 'approved' && registration.approvalReason) {
                    detailsHTML += '<div class="mt-4 p-4 border border-green-200 rounded-lg bg-green-50">' +
                            '<h5 class="font-semibold mb-2" style="color: #378A5E;">Approval Details</h5>' +
                            '<div class="detail-row">' +
                            '<div class="detail-label">Reason</div>' +
                            '<div class="detail-value">' + registration.approvalReason + '</div>' +
                            '</div>' +
                            '</div>';
                }

                // Add rejection details if rejected
                if (registration.status === 'rejected' && registration.rejectionReason) {
                    detailsHTML += '<div class="mt-4 p-4 border border-red-200 rounded-lg bg-red-50">' +
                            '<h5 class="font-semibold mb-2" style="color: #B84A4A;">Rejection Details</h5>' +
                            '<div class="detail-row">' +
                            '<div class="detail-label">Reason</div>' +
                            '<div class="detail-value">' + registration.rejectionReason + '</div>' +
                            '</div>' +
                            '</div>';
                }

                detailsHTML += '</div>';
            } else {
                // Adopter registration
                detailsHTML = '<div class="mb-6">' +
                        '<div class="flex items-center justify-between mb-4">' +
                        '<div>' +
                        '<h4 class="text-lg font-bold" style="color: #2B2B2B;">' + registration.name + '</h4>' +
                        '<p class="text-gray-500">' + registration.email + '</p>' +
                        '</div>' +
                        '<div>' +
                        '<span class="status-badge ' + statusClass + '">' + registration.status.charAt(0).toUpperCase() + registration.status.slice(1) + '</span>' +
                        '</div>' +
                        '</div>' +
                        '<div class="bg-[#F6F3E7] p-4 rounded-lg mb-4">' +
                        '<h5 class="font-semibold mb-2" style="color: #2F5D50;">Adopter Information</h5>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Phone</div>' +
                        '<div class="detail-value">' + (registration.details.phone || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Address</div>' +
                        '<div class="detail-value">' + (registration.details.address || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Occupation</div>' +
                        '<div class="detail-value">' + (registration.details.occupation || 'N/A') + '</div>' +
                        '</div>' +
                        '<div class="detail-row">' +
                        '<div class="detail-label">Household Type</div>' +
                        '<div class="detail-value">' + (registration.details.homeType || 'N/A') + '</div>' +
                        '</div>' +
                        '</div>' +
                        '<div>' +
                        '<h5 class="font-semibold mb-2" style="color: #2F5D50;">Reason for Adoption</h5>' +
                        '<p class="text-gray-700">' + (registration.details.reason || 'Looking to adopt a pet') + '</p>' +
                        '</div>' +
                        '</div>';
            }

            modalContent.innerHTML = detailsHTML;

            // Show/hide action buttons based on status
            if (registration.type === 'Shelter' && registration.status === 'pending') {
                modalApproveBtn.style.display = 'inline-block';
                modalRejectBtn.style.display = 'inline-block';
            } else {
                modalApproveBtn.style.display = 'none';
                modalRejectBtn.style.display = 'none';
            }

            // Show modal
            registrationModal.classList.add('active');
        }

        // Show toast notification
        function showToast(message, type = 'success') {
            toastMessage.textContent = message;

            if (type === 'success') {
                toast.className = 'toast toast-success';
                toastIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>';
            } else {
                toast.className = 'toast toast-error';
                toastIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>';
            }

            toast.classList.add('show');

            setTimeout(() => {
                toast.classList.remove('show');
            }, 3000);
        }

        // Initialize the page when DOM is loaded
        document.addEventListener('DOMContentLoaded', init);
    </script>

</body>
</html>