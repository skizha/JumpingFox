using JumpingFox.Models;

namespace JumpingFox.Services
{
    public interface IDataService
    {
        Task<List<Fox>> GetAllFoxesAsync();
        Task<Fox?> GetFoxByIdAsync(int id);
        Task<Fox> CreateFoxAsync(Fox fox);
        Task<Fox?> UpdateFoxAsync(int id, Fox fox);
        Task<bool> DeleteFoxAsync(int id);
        Task<List<JumpRecord>> GetJumpRecordsAsync(int? foxId = null);
        Task<JumpRecord> CreateJumpRecordAsync(JumpRecord jumpRecord);
    }

    public class DataService : IDataService
    {
        private readonly List<Fox> _foxes = new();
        private readonly List<JumpRecord> _jumpRecords = new();
        private int _nextFoxId = 1;
        private int _nextJumpId = 1;

        public DataService()
        {
            // Seed with some initial data
            SeedData();
        }

        private void SeedData()
        {
            var foxes = new List<Fox>
            {
                new() { Id = _nextFoxId++, Name = "Red Runner", Color = "Red", JumpHeight = 5, CreatedAt = DateTime.UtcNow.AddDays(-10), IsActive = true },
                new() { Id = _nextFoxId++, Name = "Silver Leaper", Color = "Silver", JumpHeight = 7, CreatedAt = DateTime.UtcNow.AddDays(-8), IsActive = true },
                new() { Id = _nextFoxId++, Name = "Golden Jumper", Color = "Golden", JumpHeight = 6, CreatedAt = DateTime.UtcNow.AddDays(-5), IsActive = true },
                new() { Id = _nextFoxId++, Name = "Arctic Springer", Color = "White", JumpHeight = 8, CreatedAt = DateTime.UtcNow.AddDays(-3), IsActive = false },
                new() { Id = _nextFoxId++, Name = "Midnight Hopper", Color = "Black", JumpHeight = 9, CreatedAt = DateTime.UtcNow.AddDays(-1), IsActive = true }
            };

            _foxes.AddRange(foxes);

            // Add some jump records
            var random = new Random();
            foreach (var fox in foxes)
            {
                for (int i = 0; i < random.Next(2, 6); i++)
                {
                    _jumpRecords.Add(new JumpRecord
                    {
                        Id = _nextJumpId++,
                        FoxId = fox.Id,
                        Height = random.Next(fox.JumpHeight - 2, fox.JumpHeight + 3),
                        JumpTime = DateTime.UtcNow.AddDays(-random.Next(0, 30)),
                        Location = GetRandomLocation()
                    });
                }
            }
        }

        private string GetRandomLocation()
        {
            var locations = new[] { "Forest Clearing", "Mountain Ridge", "Valley Floor", "River Bank", "Meadow Edge", "Rock Formation" };
            return locations[new Random().Next(locations.Length)];
        }

        public async Task<List<Fox>> GetAllFoxesAsync()
        {
            await Task.Delay(50); // Simulate async operation
            return _foxes.ToList();
        }

        public async Task<Fox?> GetFoxByIdAsync(int id)
        {
            await Task.Delay(30);
            return _foxes.FirstOrDefault(f => f.Id == id);
        }

        public async Task<Fox> CreateFoxAsync(Fox fox)
        {
            await Task.Delay(100);
            fox.Id = _nextFoxId++;
            fox.CreatedAt = DateTime.UtcNow;
            _foxes.Add(fox);
            return fox;
        }

        public async Task<Fox?> UpdateFoxAsync(int id, Fox fox)
        {
            await Task.Delay(80);
            var existingFox = _foxes.FirstOrDefault(f => f.Id == id);
            if (existingFox == null) return null;

            existingFox.Name = fox.Name;
            existingFox.Color = fox.Color;
            existingFox.JumpHeight = fox.JumpHeight;
            existingFox.IsActive = fox.IsActive;
            
            return existingFox;
        }

        public async Task<bool> DeleteFoxAsync(int id)
        {
            await Task.Delay(60);
            var fox = _foxes.FirstOrDefault(f => f.Id == id);
            if (fox == null) return false;

            _foxes.Remove(fox);
            // Also remove related jump records
            _jumpRecords.RemoveAll(jr => jr.FoxId == id);
            return true;
        }

        public async Task<List<JumpRecord>> GetJumpRecordsAsync(int? foxId = null)
        {
            await Task.Delay(40);
            if (foxId.HasValue)
                return _jumpRecords.Where(jr => jr.FoxId == foxId.Value).ToList();
            
            return _jumpRecords.ToList();
        }

        public async Task<JumpRecord> CreateJumpRecordAsync(JumpRecord jumpRecord)
        {
            await Task.Delay(70);
            jumpRecord.Id = _nextJumpId++;
            jumpRecord.JumpTime = DateTime.UtcNow;
            _jumpRecords.Add(jumpRecord);
            return jumpRecord;
        }
    }
}
