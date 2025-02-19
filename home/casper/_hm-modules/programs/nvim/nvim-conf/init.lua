-- AI setup
local conf = {
  openai_api_key = os.getenv("OPENAI_API_KEY"),
  providers = { 
    -- secrets can be strings or tables with command and arguments 
    -- secret = { "cat", "path_to/openai_api_key" }, 
    -- secret = { "bw", "get", "password", "OPENAI_API_KEY" }, 
    -- secret : "sk-...", 
    -- secret = os.getenv("env_name.."), 
    openai = { 
      disable = true, 
      endpoint = "https://api.openai.com/v1/chat/completions", 
      secret = os.getenv("OPENAI_API_KEY"), 
    }, 
    ollama = { 
      disable = false, 
      endpoint = "http://192.168.178.49:11434/v1/chat/completions", 
      secret = "", 
    } 
  }, 
  default_command_agent = "qwen2.5-coder",
  default_chat_agent = "qwen2.5-coder",
  agents = {
    {
			provider = "ollama",
			name = "qwen2.5-coder",
			chat = true,
			command = true,
			model = {
				model = "qwen2.5-coder:14b",
				temperature = 0.6,
				top_p = 1,
				min_p = 0.05,
			},
			system_prompt = "You are a general AI assistant.",
		}
  }
}
require("gp").setup(conf)



