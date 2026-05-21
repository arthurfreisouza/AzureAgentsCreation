import os
from pathlib import Path
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import PromptAgentDefinition
from azure.ai.agents import AgentsClient

def load_environment_var():
    """Load environment variables from .env file."""
    load_dotenv()
    model_name = os.getenv("MODEL_NAME", "gpt-4.1")  # Use Global Standard model
    agent_name = os.getenv("AGENT_NAME", "trail-guide-v1")
    return model_name, agent_name


def load_file(file_path):
    """Load content from a file."""
    with open(file_path, 'r') as f:
        content = f.read().strip()
    return content


def create_new_foundry_agent(model_name, agent_name, system_prompt, description):
    """Create a versioned Prompt Agent in the NEW Foundry (azure-ai-projects)."""
    project_client = AIProjectClient(
        endpoint=os.environ["ARTHUR_NEW_ENDPOINT_TEST"],
        credential=DefaultAzureCredential(),
    )

    agent = project_client.agents.create_version(
        agent_name=agent_name,
        definition=PromptAgentDefinition(
            model=model_name,
            instructions=system_prompt,
        ),
        description=description,
    )
    print(f"[New Foundry] Agent created (id: {agent.id}, name: {agent.name}, version: {agent.version})")
    return agent


def create_old_foundry_agent(model_name, agent_name, system_prompt, description):
    """Create a classic (Assistants-style) agent in the OLD Foundry surface.

    These show up in the legacy 'Agents' tab in Azure AI Foundry — the one
    with threads / runs / messages. Uses the `azure-ai-agents` SDK.
    """
    agents_client = AgentsClient(
        endpoint=os.environ["ARTHUR_NEW_ENDPOINT_TEST"],
        credential=DefaultAzureCredential(),
    )

    with agents_client:
        agent = agents_client.create_agent(
            model=model_name,
            name=agent_name,
            instructions=system_prompt,
            description=description,
        )
    print(f"[Old Foundry] Agent created (id: {agent.id}, name: {agent.name})")
    return agent


def main():
    """Main function to create the Trail Guide Agent in BOTH Foundry surfaces."""
    model_name, agent_name = load_environment_var()

    # Read instructions from prompt file
    prompt_file = Path(__file__).parent / 'prompts' / 'system_prompt.txt'
    system_prompt = load_file(prompt_file)
    version_file = Path(__file__).parent / 'VERSION.md'
    agent_version = load_file(version_file)
    description = f"Trail Guide Agent - Version {agent_version}"

    # New Foundry — versioned Prompt Agent (your original flow)
    create_new_foundry_agent(model_name, agent_name, system_prompt, description)

    # Old Foundry — classic Assistants-style agent
    create_old_foundry_agent(model_name, agent_name, system_prompt, description)


if __name__ == "__main__":
    main()