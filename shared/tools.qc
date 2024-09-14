/*
WRATH: Aeon of Ruin Deathmatch Codebase
Copyright (C) 2023 - 2024  Samuel "Reki" Piper

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include "common.h"

#ifdef SSQC
void WriteColor(float msg_type, vector value)
{
	WriteByte(msg_type, value[0] * 127);
	WriteByte(msg_type, value[1] * 127);
	WriteByte(msg_type, value[2] * 127);
}

void WriteVectorB(float msg_type, vector value)
{
	WriteChar(msg_type, value[0] * 64);
	WriteChar(msg_type, value[1] * 64);
	WriteChar(msg_type, value[2] * 64);
}

void WriteVectorA(float msg_type, vector value)
{
	WriteAngle(msg_type, value[0]);
	WriteAngle(msg_type, value[1]);
	WriteAngle(msg_type, value[2]);
}

void WriteVectorL(float msg_type, vector value)
{
	WriteCoord(msg_type, value[0]);
	WriteCoord(msg_type, value[1]);
	WriteCoord(msg_type, value[2]);
}

void WriteVectorS(float msg_type, vector value)
{
	WriteShort(msg_type, value[0]);
	WriteShort(msg_type, value[1]);
	WriteShort(msg_type, value[2]);
}

void WriteVectorF(float msg_type, vector value)
{
	WriteFloat(msg_type, value[0]);
	WriteFloat(msg_type, value[1]);
	WriteFloat(msg_type, value[2]);
}
#endif
#ifdef CSQC
vector ReadColor()
{
	return [ReadByte() / 127, ReadByte() / 127, ReadByte() / 127];
}

vector ReadVectorB()
{
	return [ReadChar() / 64, ReadChar() / 64, ReadChar() / 64];
}

vector ReadVectorA()
{
	return [ReadAngle(), ReadAngle(), ReadAngle()];
}

vector ReadVectorL()
{
	return [ReadCoord(), ReadCoord(), ReadCoord()];
}

vector ReadVectorS()
{
	return [ReadShort(), ReadShort(), ReadShort()];
}

vector ReadVectorF()
{
	return [ReadFloat(), ReadFloat(), ReadFloat()];
}
#endif

float(float v0, float v1, float t) lerp =
{
  return (1 - t) * v0 + t * v1;
}

float slerp(float x0, float x1, float t)
{
	t = ((t) * (t) * (t) * ((t) * ((t) * 6 - 15) + 10));
    return x0 + t*(x1-x0);
}

vector(vector a, vector b, float mix) lerpVector =
{
	if (mix <= 0) return a;
	if (mix >= 1) return b;
	return (b * mix + a * ( 1 - mix ) );
}

float (float x, float y) angle_difference =
{
	local float a;
	a = x - y;
	a = (a + 180) % 360 - 180;
	if (a > 180) a -= 360;
	if (a < -180) a += 360;
	
	return a;
}

float round(float x)
{
	if (x - floor(x) >= 0.5)
		return ceil(x);
	else
		return floor(x);
}

float sign(float x)
{
	if (x < 0)
		return -1;
	else
		return 1;
}

float crandom()
{
	return (random() * 2) - 1;
}

float prandom(float seed)
{
	// The Reki patented "random enough, fuck it"
	// pseudo random number generator yoinked from GLSL
	seed = sin([seed, seed] * '12.9898 78.233') * 43758.5453;
	seed = fabs(seed);
	
	return (seed - floor(seed));
}

float boxesoverlap(vector m1, vector m2, vector m3, vector m4) {return m2_x >= m3_x && m1_x <= m4_x && m2_y >= m3_y && m1_y <= m4_y && m2_z >= m3_z && m1_z <= m4_z;}

// Borrowed code from COPPER Quake mod
vector CrossProduct(vector a, vector b)
{
	vector c;

	c_x = a_y * b_z - a_z * b_y;
	c_y = a_z * b_x - a_x * b_z;
	c_z = a_x * b_y - a_y * b_x;

	return c;
}
//

float DotProduct(vector a, vector b)
{
	return ((a)[0] * (b)[0] + (a)[1] * (b)[1] + (a)[2] * (b)[2]);
}

vector VectorMA(vector a, float scale, vector b, __out vector c)
{
	c[0] = a[0] + (scale * b[0]);
	c[1] = a[1] + (scale * b[1]);
	c[2] = a[2] + (scale * b[2]);
	
	return c;
}

void makevectors2(vector ang)
{
	ang_x *= -1;
	makevectors(ang);
}

float anglemod(float v)
{
	while (v >= 360)
		v = v - 360;
	while (v < 0)
		v = v + 360;
	return v;
}

void toggle_use(void)
{
	self.using = !self.using;
}

void SetMovedir(void)
{ 
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';
	else
	{
		makevectors2(self.angles);
		self.movedir = v_forward;
	}
	self.angles = '0 0 0';
}

void SUB_Remove(void)
{
	remove(self);
}

void SUB_Null(void)
{
	return;
}
