using Microsoft.AspNetCore.Mvc;
using JumpingFox.Models;
using JumpingFox.Services;

namespace JumpingFox.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FoxController : ControllerBase
    {
        private readonly IDataService _dataService;
        private readonly IMetricsService _metricsService;
        private readonly ILogger<FoxController> _logger;

        public FoxController(IDataService dataService, IMetricsService metricsService, ILogger<FoxController> logger)
        {
            _dataService = dataService;
            _metricsService = metricsService;
            _logger = logger;
        }

        /// <summary>
        /// Get all foxes - Good for testing rate limits on collection endpoints
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<Fox>>>> GetAllFoxes()
        {
            _metricsService.RecordRequest("GET /api/fox");
            _logger.LogInformation("Getting all foxes");

            var foxes = await _dataService.GetAllFoxesAsync();
            return Ok(new ApiResponse<List<Fox>>
            {
                Success = true,
                Data = foxes,
                Message = $"Retrieved {foxes.Count} foxes"
            });
        }

        /// <summary>
        /// Get a specific fox by ID - Good for testing rate limits on individual resource access
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ApiResponse<Fox>>> GetFox(int id)
        {
            _metricsService.RecordRequest($"GET /api/fox/{id}");
            _logger.LogInformation("Getting fox with ID: {FoxId}", id);

            var fox = await _dataService.GetFoxByIdAsync(id);
            if (fox == null)
            {
                return NotFound(new ApiResponse<Fox>
                {
                    Success = false,
                    Message = $"Fox with ID {id} not found"
                });
            }

            return Ok(new ApiResponse<Fox>
            {
                Success = true,
                Data = fox,
                Message = "Fox retrieved successfully"
            });
        }

        /// <summary>
        /// Create a new fox - Good for testing rate limits on POST operations
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<ApiResponse<Fox>>> CreateFox([FromBody] Fox fox)
        {
            _metricsService.RecordRequest("POST /api/fox");
            _logger.LogInformation("Creating new fox: {FoxName}", fox.Name);

            if (string.IsNullOrWhiteSpace(fox.Name))
            {
                return BadRequest(new ApiResponse<Fox>
                {
                    Success = false,
                    Message = "Fox name is required"
                });
            }

            var createdFox = await _dataService.CreateFoxAsync(fox);
            return CreatedAtAction(nameof(GetFox), new { id = createdFox.Id }, new ApiResponse<Fox>
            {
                Success = true,
                Data = createdFox,
                Message = "Fox created successfully"
            });
        }

        /// <summary>
        /// Update an existing fox - Good for testing rate limits on PUT operations
        /// </summary>
        [HttpPut("{id}")]
        public async Task<ActionResult<ApiResponse<Fox>>> UpdateFox(int id, [FromBody] Fox fox)
        {
            _metricsService.RecordRequest($"PUT /api/fox/{id}");
            _logger.LogInformation("Updating fox with ID: {FoxId}", id);

            var updatedFox = await _dataService.UpdateFoxAsync(id, fox);
            if (updatedFox == null)
            {
                return NotFound(new ApiResponse<Fox>
                {
                    Success = false,
                    Message = $"Fox with ID {id} not found"
                });
            }

            return Ok(new ApiResponse<Fox>
            {
                Success = true,
                Data = updatedFox,
                Message = "Fox updated successfully"
            });
        }

        /// <summary>
        /// Delete a fox - Good for testing rate limits on DELETE operations
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<ActionResult<ApiResponse<object>>> DeleteFox(int id)
        {
            _metricsService.RecordRequest($"DELETE /api/fox/{id}");
            _logger.LogInformation("Deleting fox with ID: {FoxId}", id);

            var deleted = await _dataService.DeleteFoxAsync(id);
            if (!deleted)
            {
                return NotFound(new ApiResponse<object>
                {
                    Success = false,
                    Message = $"Fox with ID {id} not found"
                });
            }

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Message = "Fox deleted successfully"
            });
        }

        /// <summary>
        /// Get active foxes only - Good for testing filtered endpoints
        /// </summary>
        [HttpGet("active")]
        public async Task<ActionResult<ApiResponse<List<Fox>>>> GetActiveFoxes()
        {
            _metricsService.RecordRequest("GET /api/fox/active");
            _logger.LogInformation("Getting active foxes");

            var allFoxes = await _dataService.GetAllFoxesAsync();
            var activeFoxes = allFoxes.Where(f => f.IsActive).ToList();

            return Ok(new ApiResponse<List<Fox>>
            {
                Success = true,
                Data = activeFoxes,
                Message = $"Retrieved {activeFoxes.Count} active foxes"
            });
        }

        /// <summary>
        /// Get foxes by color - Good for testing query parameter endpoints
        /// </summary>
        [HttpGet("by-color/{color}")]
        public async Task<ActionResult<ApiResponse<List<Fox>>>> GetFoxesByColor(string color)
        {
            _metricsService.RecordRequest($"GET /api/fox/by-color/{color}");
            _logger.LogInformation("Getting foxes by color: {Color}", color);

            var allFoxes = await _dataService.GetAllFoxesAsync();
            var foxesByColor = allFoxes.Where(f => f.Color.Equals(color, StringComparison.OrdinalIgnoreCase)).ToList();

            return Ok(new ApiResponse<List<Fox>>
            {
                Success = true,
                Data = foxesByColor,
                Message = $"Retrieved {foxesByColor.Count} {color} foxes"
            });
        }
    }
}
