using Microsoft.AspNetCore.Mvc;
using JumpingFox.Models;
using JumpingFox.Services;

namespace JumpingFox.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class JumpController : ControllerBase
    {
        private readonly IDataService _dataService;
        private readonly IMetricsService _metricsService;
        private readonly ILogger<JumpController> _logger;

        public JumpController(IDataService dataService, IMetricsService metricsService, ILogger<JumpController> logger)
        {
            _dataService = dataService;
            _metricsService = metricsService;
            _logger = logger;
        }

        /// <summary>
        /// Get all jump records - Good for testing rate limits on data-heavy endpoints
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ApiResponse<List<JumpRecord>>>> GetAllJumps()
        {
            _metricsService.RecordRequest("GET /api/jump");
            _logger.LogInformation("Getting all jump records");

            var jumps = await _dataService.GetJumpRecordsAsync();
            return Ok(new ApiResponse<List<JumpRecord>>
            {
                Success = true,
                Data = jumps,
                Message = $"Retrieved {jumps.Count} jump records"
            });
        }

        /// <summary>
        /// Get jump records for a specific fox - Good for testing filtered endpoints
        /// </summary>
        [HttpGet("fox/{foxId}")]
        public async Task<ActionResult<ApiResponse<List<JumpRecord>>>> GetJumpsByFox(int foxId)
        {
            _metricsService.RecordRequest($"GET /api/jump/fox/{foxId}");
            _logger.LogInformation("Getting jump records for fox: {FoxId}", foxId);

            // Verify fox exists
            var fox = await _dataService.GetFoxByIdAsync(foxId);
            if (fox == null)
            {
                return NotFound(new ApiResponse<List<JumpRecord>>
                {
                    Success = false,
                    Message = $"Fox with ID {foxId} not found"
                });
            }

            var jumps = await _dataService.GetJumpRecordsAsync(foxId);
            return Ok(new ApiResponse<List<JumpRecord>>
            {
                Success = true,
                Data = jumps,
                Message = $"Retrieved {jumps.Count} jump records for {fox.Name}"
            });
        }

        /// <summary>
        /// Record a new jump - Good for testing rate limits on POST operations with data processing
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<ApiResponse<JumpRecord>>> RecordJump([FromBody] JumpRecord jumpRecord)
        {
            _metricsService.RecordRequest("POST /api/jump");
            _logger.LogInformation("Recording new jump for fox: {FoxId}", jumpRecord.FoxId);

            // Verify fox exists
            var fox = await _dataService.GetFoxByIdAsync(jumpRecord.FoxId);
            if (fox == null)
            {
                return BadRequest(new ApiResponse<JumpRecord>
                {
                    Success = false,
                    Message = $"Fox with ID {jumpRecord.FoxId} not found"
                });
            }

            if (jumpRecord.Height <= 0)
            {
                return BadRequest(new ApiResponse<JumpRecord>
                {
                    Success = false,
                    Message = "Jump height must be greater than 0"
                });
            }

            var createdJump = await _dataService.CreateJumpRecordAsync(jumpRecord);
            return CreatedAtAction(nameof(GetJumpsByFox), new { foxId = createdJump.FoxId }, new ApiResponse<JumpRecord>
            {
                Success = true,
                Data = createdJump,
                Message = "Jump recorded successfully"
            });
        }

        /// <summary>
        /// Get top jumps - Good for testing computationally intensive endpoints
        /// </summary>
        [HttpGet("top/{count}")]
        public async Task<ActionResult<ApiResponse<List<JumpRecord>>>> GetTopJumps(int count = 10)
        {
            _metricsService.RecordRequest($"GET /api/jump/top/{count}");
            _logger.LogInformation("Getting top {Count} jumps", count);

            if (count <= 0 || count > 100)
            {
                return BadRequest(new ApiResponse<List<JumpRecord>>
                {
                    Success = false,
                    Message = "Count must be between 1 and 100"
                });
            }

            var allJumps = await _dataService.GetJumpRecordsAsync();
            var topJumps = allJumps.OrderByDescending(j => j.Height).Take(count).ToList();

            return Ok(new ApiResponse<List<JumpRecord>>
            {
                Success = true,
                Data = topJumps,
                Message = $"Retrieved top {topJumps.Count} jumps"
            });
        }

        /// <summary>
        /// Get jump statistics - Good for testing analytics endpoints that might be expensive
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<ApiResponse<object>>> GetJumpStats()
        {
            _metricsService.RecordRequest("GET /api/jump/stats");
            _logger.LogInformation("Calculating jump statistics");

            var allJumps = await _dataService.GetJumpRecordsAsync();
            
            if (!allJumps.Any())
            {
                return Ok(new ApiResponse<object>
                {
                    Success = true,
                    Data = new { Message = "No jump records found" },
                    Message = "No statistics available"
                });
            }

            var stats = new
            {
                TotalJumps = allJumps.Count,
                AverageHeight = Math.Round(allJumps.Average(j => j.Height), 2),
                MaxHeight = allJumps.Max(j => j.Height),
                MinHeight = allJumps.Min(j => j.Height),
                UniqueLocations = allJumps.Select(j => j.Location).Distinct().Count(),
                JumpsByLocation = allJumps.GroupBy(j => j.Location)
                    .ToDictionary(g => g.Key, g => g.Count()),
                RecentJumps = allJumps.Where(j => j.JumpTime >= DateTime.UtcNow.AddDays(-7)).Count()
            };

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = stats,
                Message = "Jump statistics calculated successfully"
            });
        }
    }
}
