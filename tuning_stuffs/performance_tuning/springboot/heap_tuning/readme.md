Idle State (500Mi Total, ~300-350Mi Used) 

     Container Limit: 500Mi total
     SoftMaxHeap: 150MB (30% of 500Mi)
     Initial Heap: 150MB
     ZGC Behavior: Stays at or below 150MB during idle
     Memory Components:
         Heap: 150MB
         Metaspace: 64MB
         Other (OpenTelemetry, threads): ~100-150MB
         Total: ~300-350Mi
             

During User Activity (Grows to ~450-500Mi) 

     User Activity: Creates objects, increases memory pressure
     ZGC Response: 
         SoftMaxHeap (150MB) is exceeded
         Heap grows toward MaxHeap (400MB)
         No OOM errors due to MaxHeap limit
         
     Memory Components:
         Heap: 250-350MB (grows with activity)
         Metaspace: 64MB
         Other: ~100-150MB
         Total: ~450-500Mi
         
     

After Activity (Returns to Idle) 

     ZUncommit: Enabled with 60-second delay
     Memory Release: After 60 seconds of idle, unused memory returned to OS
     ZProactive: Starts GC cycles to clean up
     Result: Memory usage returns to ~300-350Mi
     

Key Dynamic Memory Features 

     -XX:SoftMaxHeapSize=150m: Target that ZGC tries to stay below
     -XX:+ZProactive: Proactively starts GC before memory pressure
     -XX:+ZUncommit: Returns memory to OS when not needed
     -XX:ZUncommitDelay=60: 60-second delay before uncommitting
     -XX:MaxRAMPercentage=80.0: 80% of container memory as max

Expected Behavior Over Time
------------------------------------
Time: Application Startup
Memory: ~350Mi (Heap: 150MB + Overhead)

Time: Idle (No Users)
Memory: ~350Mi (Stays at SoftMaxHeap)

Time: User Activity Begins
Memory: Grows to ~450Mi (Heap grows to 300MB)

Time: Peak Activity
Memory: ~500Mi (Heap at 350MB, near MaxHeap)

Time: Activity Ends
Memory: Remains at ~500Mi for 60 seconds

Time: After 60 Seconds Idle
Memory: Returns to ~350Mi (Memory uncommitted to OS)