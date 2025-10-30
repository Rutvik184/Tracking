package com.tracking.data.api

import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

data class LocationRequest(
    val employee_id: Int,
    val lat_loc: Double,
    val long_loc: Double,
)

data class ApiResponse(
    val id: Int,
    val employee_id: Int,
    val lat_loc: String,
    val long_loc: String,
    val timestamp: String,
    val created_at: String,
    val db_save: Boolean
)
interface LocationApi {
    @POST("employee-live-tracking/dummy-track-location")
    suspend fun requestSendLocation(@Body body: LocationRequest): Response<ApiResponse>
}
