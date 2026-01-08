import { betterAuth } from "better-auth";
import { jwt } from "better-auth/plugins";
import bcrypt from "bcrypt";
import { customAdapter } from "./custom-adapter";

export const auth = betterAuth({
  database: customAdapter,
  
  emailAndPassword: {
    enabled: true,
    password: {
      hash: async (password: string): Promise<string> => {
        return await bcrypt.hash(password, 10);
      },
      verify: async ({ hash, password }: { hash: string; password: string }): Promise<boolean> => {
        return await bcrypt.compare(password, hash);
      }
    }
  },
  
  plugins: [
    jwt({
      jwt: {
        getSubject: (user: any) => user.id,
        definePayload: ({ user }: { user: any }) => ({
          id: user.id,
          email: user.email,
          role: user.role || "user"
        }),
        issuer: "better-auth",
        expirationTime: "15 minutes"
      }
    })
  ],
  
  secret: process.env.BETTER_AUTH_SECRET || "your-secret-key-here-min-32-chars"
});
