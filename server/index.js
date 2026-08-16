require("dotenv").config();

const express = require("express");

const app = express();

const PORT = process.env.PORT || 3000;

app.get("/health", (_, res) => {
  res.json({
    status: "ok",
    service: "assistantchat-api",
  });
});

app.post(
  "/realtime/session",
  express.text({
    type: ["application/sdp", "text/plain"],
    limit: "1mb",
  }),
  async (req, res) => {
    if (!process.env.OPENAI_API_KEY) {
      return res.status(500).json({
        error: "OPENAI_API_KEY não configurada.",
      });
    }

    if (!req.body) {
      return res.status(400).json({
        error: "SDP não informado.",
      });
    }

    const sessionConfig = {
      type: "realtime",

      model: "gpt-realtime-2.1",

      instructions: `
Você é um assistente virtual pessoal executado em um aplicativo Android.

Responda sempre em português do Brasil, exceto quando o usuário pedir outro idioma.

Seja natural, objetivo e conversacional.

Priorize respostas adequadas para interação por voz.

Evite respostas excessivamente longas quando não forem necessárias.

No futuro você poderá executar ferramentas e ações no dispositivo,
mas por enquanto apenas converse com o usuário.
      `.trim(),

      output_modalities: ["audio"],

      audio: {
        input: {
          turn_detection: {
            type: "semantic_vad",
          },
        },

        output: {
          voice: "marin",
        },
      },
    };

    try {
      const formData = new FormData();

      formData.set("sdp", req.body);

      formData.set(
        "session",
        JSON.stringify(sessionConfig),
      );

      const openAIResponse = await fetch(
        "https://api.openai.com/v1/realtime/calls",
        {
          method: "POST",

          headers: {
            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          },

          body: formData,
        },
      );

      const responseBody =
        await openAIResponse.text();

      if (!openAIResponse.ok) {
        console.error(
          "OpenAI Realtime error:",
          openAIResponse.status,
          responseBody,
        );

        return res
          .status(openAIResponse.status)
          .send(responseBody);
      }

      res
        .status(200)
        .type("application/sdp")
        .send(responseBody);
    } catch (error) {
      console.error(
        "Erro ao criar sessão Realtime:",
        error,
      );

      res.status(500).json({
        error:
          "Não foi possível criar a sessão Realtime.",
      });
    }
  },
);

app.listen(PORT, "0.0.0.0", () => {
  console.log(
    `AssistantChat API rodando na porta ${PORT}`,
  );
});