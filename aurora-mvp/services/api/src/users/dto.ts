import { IsString, IsUUID, MinLength } from 'class-validator';

export class BlockDto {
  @IsUUID()
  targetUserId!: string;
}

export class ReportDto {
  @IsUUID()
  targetUserId!: string;

  @IsString()
  @MinLength(2)
  reason!: string;

  @IsString()
  details: string = '';
}
