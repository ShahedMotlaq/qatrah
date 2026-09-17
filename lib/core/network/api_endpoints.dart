class ApiEndpoints {
  ApiEndpoints._();

  // Auth — mobile app. CITIZEN and OPERATOR share one set of routes; the
  // login response's `role` decides which experience to open. ADMIN signs in
  // on the web dashboard (`/auth/admin/*`) and is not reachable from here.
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String register = '/auth/citizen/register';

  //OTP
  static const String sendOtp = '/auth/citizen/otp/send';
  static const String verifyOtp = '/auth/citizen/otp/verify';

  //Location Hierarchy
  static const String getRegions = '/regions';
  static const String getUnits = '/units';
  static const String getNeighborhoods = '/neighborhoods';
  static const String getZones = '/zones';
  /// `/hierarchy/tree` — the whole location tree in one request: only active
  /// nodes whose ancestors are all active, children sorted by id.
  static const String hierarchyTree = '/hierarchy/tree';
  static const String activeRegions = '/regions/active';
  static String hierarchyWatch(int areaId) => '/hierarchy/$areaId/watch';
  static String activeUnitsByRegion(int regionId) =>
      '/units/region/$regionId/active';
  static String neighborhoodsByRegion(int regionId) =>
      '/neighborhoods/region/$regionId';
  static String zonesByRegion(int regionId) => '/zones/region/$regionId';

  static const String updateProfile = '/users/me/profile';
  static const String currentUser = '/users/me';
  static const String addresses = '/addresses';

  /// `/me/locations/{id}/pumping-stream` — the citizen's live pumping feed for
  /// one saved location (SSE). Staff have no equivalent stream.
  static String pumpingStream(int locationId) =>
      '/me/locations/$locationId/pumping-stream';
  static const String serverState = '/server-state';
  static const String appVersion = '/app-version';

  // Complaints
  static const String complaints = '/complaints';
  static const String complaintsAll = '/complaints/all';
  static const String complaintsMy = '/complaints/my-complaints';
  static const String complaintsSearch = '/complaints/search';
  static const String complaintsStats = '/complaints/stats';
  static String complaintById(int id) => '/complaints/$id';
  static String complaintsByStatus(String status) =>
      '/complaints/status/$status';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread';
  static const String notificationsUnreadCount = '/notifications/unread/count';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsDeviceToken = '/notifications/device-token';
  static const String notificationsPublic = '/notifications/public';
  static String notificationRead(int id) => '/notifications/$id/read';
  static String notificationsPublicByRegion(int regionId) =>
      '/notifications/public/region/$regionId';

  /// `/staff/pumping-runs` — the list staff actually operate on: one row per
  /// pumping occurrence. Server-scoped (an operator sees only their assigned
  /// units), paginated, and filterable by `zoneId`.
  static const String staffPumpingRuns = '/staff/pumping-runs';

  // ── Schedules ────────────────────────────────────────────────────────────

  /// `/schedules` — returns ALL schedules (global view for admins).
  static const String schedules = '/schedules';

  /// `/schedules/my-schedules` — returns schedules scoped to the operator.
  static const String schedulesMy = '/schedules/my-schedules';

  /// `/schedules/home-status` — single payload for current home status:
  /// active, recent-cancelled, and last-completed.
  static const String schedulesHomeStatus = '/schedules/home-status';

  /// `/schedules/zone/{id}` — zone-scoped schedules list.
  static String schedulesByZone(int zoneId) => '/schedules/zone/$zoneId';

  /// `/schedules/neighborhood/{id}` — returns all schedules (active, upcoming,
  /// completed, cancelled) for a specific neighbourhood.
  /// Preferred over the generic public endpoint when a `neighborhoodId` is
  /// known because it avoids client-side filtering over a larger dataset.
  static String schedulesByNeighborhood(int neighborhoodId) =>
      '/schedules/neighborhood/$neighborhoodId';

  /// `/schedules/public` — generic public schedules endpoint used as a
  /// fallback when no neighbourhood ID is available.
  static const String schedulesPublic = '/schedules/public';

  /// `/schedules/public/region/{id}/date-range` — region-scoped schedules
  /// filtered by a start/end date range.
  static String schedulesPublicRegionDateRange(int regionId) =>
      '/schedules/public/region/$regionId/date-range';

  /// `/schedules/{id}` — update an existing schedule.
  static String updateSchedule(int id) => '/schedules/$id';

  /// `/schedules/{id}/start` — start a scheduled pumping session.
  static String startSchedule(int id) => '/schedules/$id/start';

  /// `/schedules/{id}/end` — end an active pumping session.
  static String endSchedule(int id) => '/schedules/$id/end';

  /// `/schedules/{id}/pause` — pause an active schedule.
  static String pauseSchedule(int id) => '/schedules/$id/pause';

  /// `/schedules/{id}/resume` — resume a paused schedule.
  static String resumeSchedule(int id) => '/schedules/$id/resume';

  /// `/schedules/{id}/cancel` — cancel a schedule.
  static String cancelSchedule(int id) => '/schedules/$id/cancel';

  /// `/schedules/{id}/shift` — delay a persistent schedule by a number of
  /// hours (start and end times are shifted together by the backend).
  static String shiftSchedule(int id) => '/schedules/$id/shift';

  // Water Feedback
  static const String waterFeedback = '/water-feedback';
  static const String waterFeedbackActiveScheduleStatus =
      '/water-feedback/active-schedule-status';
  static const String waterFeedbackMyFeedback = '/water-feedback/my-feedback';
  static String waterFeedbackUserFeedback(int scheduleId) =>
      '/water-feedback/schedule/$scheduleId/user-feedback';
}
