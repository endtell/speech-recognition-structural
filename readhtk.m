function [d,fp,dt,tc,t]=readhtk(file)
%READHTK  read an HTK parameter file [d,fp,dt,tc,t]=readhtk(file)
%
% Input:
%    file = name of HTK file
% Outputs:
%       d = data: column vector for waveforms, one column per frame for other types
%      fp = frame period in seconds
%      dt = data type (also includes Voicebox code for generating data)
%             0  WAVEFORM     Acoustic waveform
%             1  LPC          Linear prediction coefficients
%             2  LPREFC       LPC Reflection coefficients:  -lpcar2rf([1 LPC]);LPREFC(1)=[];
%             3  LPCEPSTRA    LPC Cepstral coefficients
%             4  LPDELCEP     LPC cepstral+delta coefficients (obsolete)
%             5  IREFC        LPC Reflection coefficients (16 bit fixed point)
%             6  MFCC         Mel frequency cepstral coefficients
%             7  FBANK        Log Fliter bank energies
%             8  MELSPEC      linear Mel-scaled spectrum
%             9  USER         User defined features
%            10  DISCRETE     Vector quantised codebook
%            11  PLP          Perceptual Linear prediction
%            12  ANON
%      tc = full type code = DT plus (optionally) one or more of the following modifiers
%               64  _E  Includes energy terms
%              128  _N  Suppress absolute energy
%              256  _D  Include delta coefs
%              512  _A  Include acceleration coefs
%             1024  _C  Compressed
%             2048  _Z  Zero mean static coefs
%             4096  _K  CRC checksum (not implemented yet)
%             8192  _0  Include 0'th cepstral coef
%            16384  _V  Attach VQ index
%            32768  _T  Attach delta-delta-delta index
%       t = text version of type code e.g. LPC_C_K

% http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html

% Copyright (C) Masayuki Suzuki
% GAVORIN is a toolbox for speech processing.

fid=fopen(file,'r','b');
if fid < 0; error( sprintf('Cannot read from %s', file) ); end
nf=fread(fid,1,'long');             % number of frames
fp=fread(fid,1,'long')*1.E-7;       % frame interval (converted to seconds)
by=fread(fid,1,'short');            % bytes per frame
tc=fread(fid,1,'short');            % type code (see comments above for interpretation)
tc=tc+65536*(tc<0);
cc='ENDACZK0VT';                    % list of suffix codes
nhb=length(cc);                     % number of suffix codes
ndt=6;                              % number of bits for base type
hb=floor(tc*pow2(-(ndt+nhb):-ndt));
hd=hb(nhb+1:-1:2)-2*hb(nhb:-1:1);   % extract bits from type code
dt=tc-pow2(hb(end),ndt);            % low six bits of tc represent data type

% hd(7)=1 CRC check
% hd(5)=1 compressed data
if (dt==5)                  % hack to fix error in IREFC files which are sometimes stored as compressed LPREFC
    fseek(fid,0,'eof');
    flen=ftell(fid);        % find length of file
    fseek(fid,12,'bof');
    if flen>14+by*nf        % if file is too long (including possible CRCC) then assume compression constants exist
        dt=2;               % change type to LPREFC
        hd(5)=1;            % set compressed flag
        nf=nf+4;            % frame count doesn't include compression constants in this case
    end
end

if any(dt==[0,5,10])        % 16 bit data for waveforms, IREFC and DISCRETE
    d=fread(fid,[by/2,nf],'short');
    if ( dt == 5),
        d=d/32767;          % scale IREFC
    end
else
    if hd(5)                % compressed data - first read scales
        nf = nf - 4;        % frame count includes compression constants
        ncol = by / 2;
        scales = fread(fid, ncol, 'float');
        biases = fread(fid, ncol, 'float');
        d = (fread(fid,[ncol, nf], 'short')+repmat(biases,1,nf)).*repmat(1./scales,1,nf);
    else                    % uncompressed data
        d=fread(fid,[by/4,nf],'float');
    end
end;
fclose(fid);
if nargout > 4
    ns=sum(hd);             % number of suffixes
    kinds={'WAVEFORM' 'LPC' 'LPREFC' 'LPCEPSTRA' 'LPDELCEP' 'IREFC' 'MFCC' 'FBANK' 'MELSPEC' 'USER' 'DISCRETE' 'PLP' 'ANON' '???'};
    t=[kinds{min(dt+1,length(kinds))} reshape(['_'*ones(1,ns);cc(hd>0)],1,2*ns)];
end
