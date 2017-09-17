function strVec=hmm2str(hmmName, dim, blockSize, useDim)
%
% USING:
%    bhattacharyya.m, structure.m, readhmm.m
%
% INPUT:
%    hmmName    : 入力となるHMMファイルの名前
%    dim        : 特徴量の次元数
%    blocksize  : マルチストリーム化の際のブロックサイズ
%    useDim     : 構造の計算に使用する次元
%                (e.g.) [m:n]   : m次からn次までを使用
%                       [1,2,3] : 1,2,3次元を使用
%
% OUTPUT
%	strVec	: 構造ベクトル
%

	% argument
	if nargin < 2 | 4 < nargin 
		error('Usage : hmm2str(hmmName, dim, [blocksize], [useDim])');
	elseif nargin ==2
		blockSize=dim;
		useDim=[1:dim];
	elseif nargin==3
		useDim=[1:dim];
	end % if

	% read hmmfile
	hmm=readhmm(hmmName);

	% extract necessary dimensions
%	size(hmm.means)
%	useDim
	tmp.mu=hmm.means(useDim, :)';
	tmp.Sigma=hmm.covars(useDim, :)';
%blockSize
	% multi stream, calcurate structure
%	  fprintf(' useDim is %d, blockSize is %d + 1\n',length(useDim),blockSize);
	nStream=length(useDim)-blockSize+1	% num stream of multi stream
	strVec=[];
	for ii=1:nStream
		subStream=[ii:ii+blockSize-1];
		mu=tmp.mu(:, subStream);
		Sigma=tmp.Sigma(:, subStream);
		strVec = [strVec structure(mu,Sigma)]; % calcurate structure
	end % ii

end % function
