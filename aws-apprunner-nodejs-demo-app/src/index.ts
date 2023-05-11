import express from 'express';
import axios from 'axios';
import { VaultClient } from '@piiano/vault-client';


const app = express();
const port = 3000;

const client = new VaultClient({
  vaultURL: process.env.PVAULT_LISTEN_ADDR || "http://localhost:8123",
  apiKey: process.env.PVAULT_ADMIN_API_KEY || "pvaultauth",
});

app.get('/', async (req, res) => {
  try {
    // Example for API
    // const response = await axios.get<SystemInfo>('/api/pvlt/1.0/system/info/version', config);
    // const productVersion = response.data

    // Example for SDK
    const productVersion = await client.system.getVaultVersion();

    res.send(productVersion)

  } catch (error) {
    console.error(error);
    res.status(500).send('Something went wrong!');
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

