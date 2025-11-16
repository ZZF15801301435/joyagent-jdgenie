# -*- coding: utf-8 -*-
# =====================
# 
# 
# Author: liumin.423
# Date:   2025/7/8
# =====================
import json
import os
from typing import List, Any, Optional

from litellm import acompletion

from genie_tool.util.log_util import timer, AsyncTimer
from genie_tool.util.sensitive_detection import SensitiveWordsReplace


@timer(key="enter")
async def ask_llm(
        messages: str | List[Any],
        model: str,
        temperature: float = None,
        top_p: float = None,
        stream: bool = False,

        # 自定义字段
        only_content: bool = False,     # 只返回内容

        extra_headers: Optional[dict] = None,
        **kwargs,
):
    if isinstance(messages, str):
        messages = [{"role": "user", "content": messages}]
    if os.getenv("SENSITIVE_WORD_REPLACE", "false") == "true":
        for message in messages:
            if isinstance(message.get("content"), str):
                message["content"] = SensitiveWordsReplace.replace(message["content"])
            else:
                message["content"] = json.loads(
                    SensitiveWordsReplace.replace(json.dumps(message["content"], ensure_ascii=False)))
    
    # 处理 DeepSeek 模型名称和 API 配置
    # litellm 对于使用 OpenAI 兼容 API 的自定义端点，需要使用 openai/model_name 格式
    if model and (model == "deepseek-chat" or model.startswith("deepseek/")):
        # 转换为 litellm 识别的格式：openai/deepseek-chat
        if model.startswith("deepseek/"):
            model = model.replace("deepseek/", "openai/")
        else:
            model = f"openai/{model}"
    
    # 获取 API 配置
    api_base = os.getenv("OPENAI_BASE_URL") or os.getenv("DEEPSEEK_API_BASE")
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("DEEPSEEK_API_KEY")
    
    # 构建调用参数
    completion_kwargs = {
        "messages": messages,
        "model": model,
        "stream": stream,
    }
    
    # 只添加有效的参数（None 或 0 的值不传递，让 API 使用默认值）
    if temperature is not None:
        completion_kwargs["temperature"] = temperature
    # DeepSeek API 要求 top_p 必须在 (0, 1.0] 范围内，不能是 0 或 None
    if top_p is not None and top_p > 0:
        completion_kwargs["top_p"] = top_p
    
    # 如果提供了 api_base 和 api_key，传递给 litellm
    if api_base:
        completion_kwargs["api_base"] = api_base
    if api_key:
        completion_kwargs["api_key"] = api_key
    
    # 添加额外的 headers 和其他 kwargs
    if extra_headers:
        completion_kwargs["extra_headers"] = extra_headers
    completion_kwargs.update(kwargs)
    
    response = await acompletion(**completion_kwargs)
    async with AsyncTimer(key=f"exec ask_llm"):
        if stream:
            async for chunk in response:
                if only_content:
                    if chunk.choices and chunk.choices[0] and chunk.choices[0].delta and chunk.choices[0].delta.content:
                        yield chunk.choices[0].delta.content
                else:
                    yield chunk
        else:
            yield response.choices[0].message.content if only_content else response


if __name__ == "__main__":
    pass
