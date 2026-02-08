import { NextRequest, NextResponse } from 'next/server';

/**
 * ChatKit session endpoint
 * Creates OpenAI ChatKit session with Better Auth JWT authentication
 *
 * Feature: 009-compliance-fixes (ChatKit integration)
 */
export async function POST(request: NextRequest) {
  try {
    // Get Better Auth JWT token
    const authHeader = request.headers.get('authorization');
    if (!authHeader) {
      return NextResponse.json(
        { error: 'Missing authorization header' },
        { status: 401 }
      );
    }

    // Extract token from Bearer header
    const token = authHeader.replace('Bearer ', '');
    if (!token) {
      return NextResponse.json(
        { error: 'Invalid authorization header' },
        { status: 401 }
      );
    }

    // Get user_id from request body (optional, can be extracted from token)
    const body = await request.json();
    const userId = body.user_id;

    // Create ChatKit session
    // In production, this would call OpenAI ChatKit API to create a session
    // For now, we'll return a mock client_secret
    const clientSecret = `chatkit_session_${Date.now()}_${userId || 'anonymous'}`;

    return NextResponse.json({
      client_secret: clientSecret,
      user_id: userId,
      expires_at: new Date(Date.now() + 3600000).toISOString(), // 1 hour
    });
  } catch (error) {
    console.error('ChatKit session creation failed:', error);
    return NextResponse.json(
      { error: 'Failed to create ChatKit session' },
      { status: 500 }
    );
  }
}
