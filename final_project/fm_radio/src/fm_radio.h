
#ifndef __FM_RADIO_H__
#define __FM_RADIO_H__

#include <math.h>

#define _VC_

// quantization
#define BITS            10
#define QUANT_VAL       (1 << BITS)
#define QUANTIZE_F(f)   (int)(((float)(f) * (float)QUANT_VAL))
#define QUANTIZE_I(i)   (int)((int)(i) * (int)QUANT_VAL)
#define DEQUANTIZE(i)   (int)((int)(i) / (int)QUANT_VAL)

// constants
#define PI              3.1415926535897932384626433832795f
#define ADC_RATE        64000000 // 64 MS/s
#define USRP_DECIM      250
#define QUAD_RATE       (int)(ADC_RATE / USRP_DECIM) // 256 kS/s
#define AUDIO_DECIM     8
#define AUDIO_RATE      (int)(QUAD_RATE / AUDIO_DECIM) // 32 kHz
#define VOLUME_LEVEL    QUANTIZE_F(1.0f)
#define SAMPLES         65536*4
#define AUDIO_SAMPLES   (int)(SAMPLES / AUDIO_DECIM)
#define MAX_TAPS        32 
#define MAX_DEV         55000.0f
#define FM_DEMOD_GAIN   QUANTIZE_F( (float)QUAD_RATE / (2.0f * PI * MAX_DEV) )
#define TAU             0.000075f
#define W_PP            0.21140067f //tan( 1.0f / ((float)AUDIO_RATE*2.0f*TAU) )

void fm_radio_stereo( unsigned char *IQ, int *left_audio, int *right_audio );

void read_IQ( unsigned char *IQ, int *I, int *Q, int samples );

void demodulate_n( int *real, int *imag, int *real_prev, int *imag_prev, const int n_samples, const int gain, int *demod_out );

void demodulate( int real, int imag, int *real_prev, int *imag_prev, const int gain, int *demod_out );

void deemphasis_n( int *input, int *x, int *y, const int n_samples, int *output, const std::string& str );

void iir_n( int *x_in, const int n_samples, const int *x_coeffs, const int *y_coeffs, int *x, int *y, const int taps, int decimation, int *y_out, const std::string& str );

void iir( int *x_in, const int *x_coeffs, const int *y_coeffs, int *x, int *y, const int taps, const int decimation, int *y_out );

void fir_n( int *x_in, const int n_samples, const int *coeff, int *x, const int taps, const int decimation, int *y_out, const std::string& str ); 

void fir( int *x_in, const int *coeff, int *x, const int taps, const int decimation, int *y_out ); 

void fir_cmplx_n( int *x_real_in, int *x_imag_in, const int n_samples, const int *h_real, const int *h_imag, int *x_real, int *x_imag,  
                  const int taps, const int decimation, int *y_real_out, int *y_imag_out );

void fir_cmplx( int *x_real_in, int *x_imag_in, const int *h_real, const int *h_imag, int *x_real, int *x_imag, 
                const int taps, const int decimation, int *y_real_out, int *y_imag_out );

void gain_n( int *input, const int n_samples, int gain, int *output, const std::string& str );

int qarctan(int y, int x);

void multiply_n( int *x_in, int *y_in, const int n_samples, int *output, const std::string& str );

void add_n( int *x_in, int *y_in, const int n_samples, int *output );

void sub_n( int *x_in, int *y_in, const int n_samples, int *output );


// Deemphasis IIR Filter Coefficients: 
static const int IIR_COEFF_TAPS = 2;
static const int IIR_Y_COEFFS[] = {QUANTIZE_F(0.0f), QUANTIZE_F((W_PP - 1.0f) / (W_PP + 1.0f))};
static const int IIR_X_COEFFS[] = {QUANTIZE_F(W_PP / (1.0f + W_PP)), QUANTIZE_F(W_PP / (1.0f + W_PP))};

// Channel low-pass complex filter coefficients @ 0kHz to 80kHz
static const int CHANNEL_COEFF_TAPS = 20;
static const int CHANNEL_COEFFS_REAL[] =
{
	0x00000001, 0x00000008, 0xfffffff3, 0x00000009, 0x0000000b, 0xffffffd3, 0x00000045, 0xffffffd3, 
	0xffffffb1, 0x00000257, 0x00000257, 0xffffffb1, 0xffffffd3, 0x00000045, 0xffffffd3, 0x0000000b, 
	0x00000009, 0xfffffff3, 0x00000008, 0x00000001
};

static const int CHANNEL_COEFFS_IMAG[] =
{
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
	0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 
	0x00000000, 0x00000000, 0x00000000, 0x00000000
};

// L+R low-pass filter coefficients @ 15kHz
static const int AUDIO_LPR_COEFF_TAPS = 32;
static const int AUDIO_LPR_COEFFS[] =
{
	0xfffffffd, 0xfffffffa, 0xfffffff4, 0xffffffed, 0xffffffe5, 0xffffffdf, 0xffffffe2, 0xfffffff3, 
	0x00000015, 0x0000004e, 0x0000009b, 0x000000f9, 0x0000015d, 0x000001be, 0x0000020e, 0x00000243, 
	0x00000243, 0x0000020e, 0x000001be, 0x0000015d, 0x000000f9, 0x0000009b, 0x0000004e, 0x00000015, 
	0xfffffff3, 0xffffffe2, 0xffffffdf, 0xffffffe5, 0xffffffed, 0xfffffff4, 0xfffffffa, 0xfffffffd
};

// L-R low-pass filter coefficients @ 15kHz, gain = 60
static const int AUDIO_LMR_COEFF_TAPS = 32;
static const int AUDIO_LMR_COEFFS[] =
{
	0xfffffffd, 0xfffffffa, 0xfffffff4, 0xffffffed, 0xffffffe5, 0xffffffdf, 0xffffffe2, 0xfffffff3, 
	0x00000015, 0x0000004e, 0x0000009b, 0x000000f9, 0x0000015d, 0x000001be, 0x0000020e, 0x00000243, 
	0x00000243, 0x0000020e, 0x000001be, 0x0000015d, 0x000000f9, 0x0000009b, 0x0000004e, 0x00000015, 
      0xfffffff3, 0xffffffe2, 0xffffffdf, 0xffffffe5, 0xffffffed, 0xfffffff4, 0xfffffffa, 0xfffffffd
};

// Pilot tone band-pass filter @ 19kHz
static const int BP_PILOT_COEFF_TAPS = 32;
static const int BP_PILOT_COEFFS[] =
{
	0x0000000e, 0x0000001f, 0x00000034, 0x00000048, 0x0000004e, 0x00000036, 0xfffffff8, 0xffffff98, 
	0xffffff2d, 0xfffffeda, 0xfffffec3, 0xfffffefe, 0xffffff8a, 0x0000004a, 0x0000010f, 0x000001a1, 
	0x000001a1, 0x0000010f, 0x0000004a, 0xffffff8a, 0xfffffefe, 0xfffffec3, 0xfffffeda, 0xffffff2d, 
	0xffffff98, 0xfffffff8, 0x00000036, 0x0000004e, 0x00000048, 0x00000034, 0x0000001f, 0x0000000e
};

// L-R band-pass filter @ 23kHz to 53kHz
static const int BP_LMR_COEFF_TAPS = 32;
static const int BP_LMR_COEFFS[] =
{
	0x00000000, 0x00000000, 0xfffffffc, 0xfffffff9, 0xfffffffe, 0x00000008, 0x0000000c, 0x00000002, 
	0x00000003, 0x0000001e, 0x00000030, 0xfffffffc, 0xffffff8c, 0xffffff58, 0xffffffc3, 0x0000008a, 
	0x0000008a, 0xffffffc3, 0xffffff58, 0xffffff8c, 0xfffffffc, 0x00000030, 0x0000001e, 0x00000003, 
	0x00000002, 0x0000000c, 0x00000008, 0xfffffffe, 0xfffffff9, 0xfffffffc, 0x00000000, 0x00000000
};

// High pass filter @ 0Hz removes noise after pilot tone is squared
static const int HP_COEFF_TAPS = 32;
static const int HP_COEFFS[] =
{
	0xffffffff, 0x00000000, 0x00000000, 0x00000002, 0x00000004, 0x00000008, 0x0000000b, 0x0000000c, 
	0x00000008, 0xffffffff, 0xffffffee, 0xffffffd7, 0xffffffbb, 0xffffff9f, 0xffffff87, 0xffffff76, 
	0xffffff76, 0xffffff87, 0xffffff9f, 0xffffffbb, 0xffffffd7, 0xffffffee, 0xffffffff, 0x00000008, 
	0x0000000c, 0x0000000b, 0x00000008, 0x00000004, 0x00000002, 0x00000000, 0x00000000, 0xffffffff
};


#endif
