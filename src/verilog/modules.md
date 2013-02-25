This file contains a list of the modules that will need to be implemented and their relationships.
It is a design document intended to guide me in my implementation of the OpenFlow switch.
I will be using the reference router as a barebones framework from which to work with.

    user_data_path
    |
    +---input_arbiter
    |
    +---header_parser
    |
    +---flow_lookup
    |   |
    |   +---exact_matcher
    |   |
    |   +---wildcard_matcher
    |
    +---action_modifier
    |
    +---output_queue
    
User Data Path
--------------

### Parameters:
- Data Width
- Ctrl Width
- UDP (User data path) Register Src Width
- Number io queues
- SRAM data bus width
- SRAM adress bus width

### Inputs:
- 8 Interfaces (4 phy, 4 virt)
    - Data
    - Ctrl
    - Write
    - Ready
- SRAM Interface
    - Write Request
    - Write Address
    - Write Ack
    - Write Data

### Outputs:
- 8 Interfaces (4 phy, 4 virt)
    - Data
    - Ctrl
    - Write
    - Ready
- SRAM Interface
    - Read Request
    - Read Address
    - Read Ack
    - Read Data
    - Read Valid
    
### 

